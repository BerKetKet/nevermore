import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: termTabRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property string userHome: String(StandardPaths.writableLocation(StandardPaths.HomeLocation)).replace(/^file:\/\//, "")

    // --- State: Terminal Status ---
    property string terminalStatus: "stopped" // "stopped", "running", "unknown"
    property string terminalVisibility: "hidden" // "active", "visible", "minimized", "hidden"
    property string terminalGeometry: ""
    property int terminalPid: -1

    // --- State: Background Tasks ---
    property var bgTasks: []
    property bool hasRunningTasks: false
    property string currentLogUnit: ""
    property string currentLogText: ""
    property bool showLogs: false

    readonly property bool shouldPollTasks: termTabRoot.visible || hasRunningTasks

    // Polling timer for background tasks
    Timer {
        id: taskPollTimer
        interval: termTabRoot.hasRunningTasks ? 3000 : 5000
        repeat: true
        running: termTabRoot.shouldPollTasks
        onTriggered: termTabRoot.pollTasks()
    }

    Timer {
        id: taskRefreshTimer
        interval: 350
        repeat: false
        onTriggered: termTabRoot.pollTasks()
    }

    // Polling timer for terminal status
    Timer {
        id: termStatusTimer
        interval: 2500
        repeat: true
        running: termTabRoot.visible
        onTriggered: termTabRoot.pollTermStatus()
    }

    onVisibleChanged: {
        if (visible) {
            termTabRoot.pollTermStatus();
            termTabRoot.pollTasks();
        }
    }

    // --- Data Sources via Plasma5Support ---

    // Terminal Control Engine
    Plasma5Support.DataSource {
        id: termEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            if (source.indexOf("nevermore-term status") !== -1) {
                let out = (data["stdout"] || "").trim();
                let lines = out.split("\n");
                let st = "stopped";
                let vis = "hidden";
                let geom = "";
                let pid = -1;

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.startsWith("status: ")) st = line.substring(8).trim();
                    else if (line.startsWith("visibility: ")) vis = line.substring(12).trim();
                    else if (line.startsWith("geometry: ")) geom = line.substring(10).trim();
                    else if (line.startsWith("pid: ")) {
                        let p = parseInt(line.substring(5).trim(), 10);
                        if (!isNaN(p)) pid = p;
                    }
                }

                termTabRoot.terminalStatus = st;
                termTabRoot.terminalVisibility = vis;
                termTabRoot.terminalGeometry = geom;
                termTabRoot.terminalPid = pid;
            } else if (source.indexOf("nevermore-term toggle") !== -1) {
                // Refresh status shortly after toggle
                termStatusTimer.restart();
                termTabRoot.pollTermStatus();
            }
        }
    }

    // Tasks Polling Engine
    Plasma5Support.DataSource {
        id: taskPollEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            let out = (data["stdout"] || "").trim();
            try {
                let parsed = JSON.parse(out);
                if (Array.isArray(parsed)) {
                    let validList = [];
                    let anyRunning = false;
                    for (let i = 0; i < parsed.length; i++) {
                        let item = parsed[i];
                        if (termTabRoot.isValidUnitName(item.unit)) {
                            let category = "other";
                            if (item.sub === "running") {
                                category = "running";
                                anyRunning = true;
                            } else if (item.active === "failed" || item.sub === "failed") {
                                category = "failed";
                            } else if (item.sub === "exited") {
                                category = "exited";
                            } else {
                                category = item.sub || item.active || "other";
                            }
                            item.statusCategory = category;
                            validList.push(item);
                        }
                    }
                    termTabRoot.hasRunningTasks = anyRunning;
                    termTabRoot.bgTasks = validList;

                    if (validList.length > 0) {
                        taskShowEngine.connectSource("systemctl --user show \"nevermore-task-*\" --property=Id,ExecMainStatus");
                    }
                }
            } catch (e) {
                // JSON parse error or empty
            }
        }
    }

    // Tasks Exit Code Detail Engine
    Plasma5Support.DataSource {
        id: taskShowEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            let out = (data["stdout"] || "").trim();
            if (out.length === 0) return;

            let statusMap = {};
            let lines = out.split("\n");
            let currentId = "";

            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim();
                if (line.startsWith("Id=")) {
                    currentId = line.substring(3).trim();
                } else if (line.startsWith("ExecMainStatus=") && currentId !== "") {
                    let st = parseInt(line.substring(15).trim(), 10);
                    if (!isNaN(st)) {
                        statusMap[currentId] = st;
                    }
                }
            }

            let tasks = termTabRoot.bgTasks.slice();
            let updatedTasks = [];
            for (let j = 0; j < tasks.length; j++) {
                let u = tasks[j].unit;
                if (statusMap[u] !== undefined) {
                    updatedTasks.push(Object.assign({}, tasks[j], { execStatus: statusMap[u] }));
                } else {
                    updatedTasks.push(Object.assign({}, tasks[j]));
                }
            }
            termTabRoot.bgTasks = updatedTasks;
        }
    }

    // Task Actions & Logs Engine
    Plasma5Support.DataSource {
        id: taskActionEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            if (source.startsWith("journalctl --user -u ")) {
                let stdout = (data["stdout"] || "").trim();
                let stderr = (data["stderr"] || "").trim();
                let combined = stdout;
                if (stderr.length > 0) {
                    if (combined.length > 0) combined += "\n";
                    combined += stderr;
                }
                if (combined.length === 0) {
                    combined = i18n("(No logs found for unit)");
                }
                termTabRoot.currentLogText = combined;
                termTabRoot.showLogs = true;
            }
        }
    }

    // Helper Execution Engine
    Plasma5Support.DataSource {
        id: helperEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
        }
    }

    // --- Action Methods ---

    function pollTermStatus() {
        termEngine.connectSource("nevermore-term status");
    }

    function toggleTerminal() {
        termEngine.connectSource("nevermore-term toggle");
    }

    function pollTasks() {
        taskPollEngine.connectSource("systemctl --user list-units \"nevermore-task-*\" --all --output=json");
    }

    function isValidUnitName(unit) {
        if (!unit || typeof unit !== "string") return false;
        return /^nevermore-task-[0-9]+\.service$/.test(unit);
    }

    function launchBackgroundTask(cmd) {
        if (!cmd || cmd.trim() === "") return;
        cmd = cmd.trim();
        let escapedCmd = cmd.replace(/'/g, "'\\''");
        let helperPath = userHome + "/.local/bin/nevermore-run";
        helperEngine.connectSource("\"" + helperPath + "\" '" + escapedCmd + "'");
        cmdInput.text = "";
        taskRefreshTimer.restart();
    }

    function viewTaskLogs(unit) {
        if (!isValidUnitName(unit)) return;
        termTabRoot.currentLogUnit = unit;
        termTabRoot.currentLogText = i18n("Loading logs...");
        termTabRoot.showLogs = true;
        taskActionEngine.connectSource("journalctl --user -u '" + unit + "' -n 200 --no-pager");
    }

    function stopOrDismissTask(unit, isFinished) {
        if (!isValidUnitName(unit)) return;
        let escaped = "'" + unit + "'";
        let cmd = "";
        if (isFinished) {
            cmd = "systemctl --user stop " + escaped + " 2>/dev/null; systemctl --user reset-failed " + escaped + " 2>/dev/null";
        } else {
            cmd = "systemctl --user stop " + escaped;
        }
        helperEngine.connectSource(cmd);
        taskRefreshTimer.restart();
    }

    function dismissAllFinishedTasks() {
        let tasks = termTabRoot.bgTasks;
        let unitsToDismiss = [];
        for (let i = 0; i < tasks.length; i++) {
            let t = tasks[i];
            if (t.statusCategory === "exited" || t.statusCategory === "failed") {
                unitsToDismiss.push("'" + t.unit + "'");
            }
        }
        if (unitsToDismiss.length === 0) return;
        let joined = unitsToDismiss.join(" ");
        helperEngine.connectSource("systemctl --user stop " + joined + " 2>/dev/null; systemctl --user reset-failed " + joined + " 2>/dev/null");
        taskRefreshTimer.restart();
    }

    // --- UI Layout ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // ==========================================
        // SECTION 1: Managed Terminal Control
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: termCol.implicitHeight + 20
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                id: termCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Title Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Kirigami.Icon {
                        source: "utilities-terminal"
                        implicitWidth: 16
                        implicitHeight: 16
                        color: "#0a84ff"
                    }

                    Text {
                        text: i18n("Slide-out Terminal")
                        font.family: "SF Hello"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    Item { Layout.fillWidth: true }

                    // Status Indicator
                    Rectangle {
                        implicitWidth: 8
                        implicitHeight: 8
                        radius: 4
                        color: termTabRoot.terminalStatus === "running"
                               ? (termTabRoot.terminalVisibility === "active" ? "#30d158" : "#ffd60a")
                               : Qt.rgba(1, 1, 1, 0.3)
                    }

                    Text {
                        text: termTabRoot.terminalStatus === "running"
                              ? (termTabRoot.terminalVisibility === "active" ? i18n("Active") : (termTabRoot.terminalVisibility === "minimized" ? i18n("Minimized") : i18n("Running")))
                              : i18n("Stopped")
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.6)
                    }
                }

                // Status Details
                Text {
                    text: termTabRoot.terminalStatus === "running"
                          ? i18n("PID %1 • Docked at right edge (%2)", termTabRoot.terminalPid, termTabRoot.terminalGeometry !== "" ? termTabRoot.terminalGeometry : "397px")
                          : i18n("Press Show Terminal or Meta+Shift+N to open")
                    font.family: "SF Hello"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.5)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // Prominent Show / Hide Button
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 8
                    color: toggleMouse.containsMouse ? "#006ee6" : "#0a84ff"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Kirigami.Icon {
                            source: termTabRoot.terminalVisibility === "active" ? "window-minimize" : "utilities-terminal"
                            implicitWidth: 16
                            implicitHeight: 16
                            color: "#ffffff"
                        }

                        Text {
                            text: termTabRoot.terminalVisibility === "active" ? i18n("Hide Terminal") : i18n("Show Terminal")
                            font.family: "SF Hello"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: termTabRoot.toggleTerminal()
                    }
                }
            }
        }

        // ==========================================
        // SECTION 2: Background Tasks
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Kirigami.Icon {
                        source: "system-switch-user"
                        implicitWidth: 15
                        implicitHeight: 15
                        color: "#bf5af2"
                    }

                    Text {
                        text: i18n("Background Tasks")
                        font.family: "SF Hello"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    Rectangle {
                        implicitWidth: Math.max(16, countText.implicitWidth + 8)
                        implicitHeight: 16
                        radius: 8
                        color: termTabRoot.hasRunningTasks ? "#bf5af2" : Qt.rgba(1, 1, 1, 0.15)
                        visible: termTabRoot.bgTasks.length > 0

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: termTabRoot.bgTasks.length
                            font.family: "SF Hello"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#ffffff"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Clear Finished Button
                    Text {
                        text: i18n("Clear Finished")
                        font.family: "SF Hello"
                        font.pixelSize: 10
                        color: clearFinishedMouse.containsMouse ? "#ff453a" : Qt.rgba(1, 1, 1, 0.4)
                        visible: {
                            for (let i = 0; i < termTabRoot.bgTasks.length; i++) {
                                if (termTabRoot.bgTasks[i].statusCategory === "exited" || termTabRoot.bgTasks[i].statusCategory === "failed") return true;
                            }
                            return false;
                        }

                        MouseArea {
                            id: clearFinishedMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: termTabRoot.dismissAllFinishedTasks()
                        }
                    }
                }

                // Command Launch Box
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 6
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.color: cmdInput.activeFocus ? "#bf5af2" : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        TextInput {
                            id: cmdInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 11
                            color: "#ffffff"
                            clip: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: i18n("Launch background command (e.g. sleep 10)...")
                                font.family: "SF Hello"
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.3)
                                visible: !cmdInput.text && !cmdInput.activeFocus
                            }

                            Keys.onReturnPressed: termTabRoot.launchBackgroundTask(cmdInput.text)
                        }
                    }

                    Rectangle {
                        implicitWidth: launchText.implicitWidth + 14
                        implicitHeight: 30
                        radius: 6
                        color: launchMouse.containsMouse ? Qt.rgba(191/255, 90/255, 242/255, 0.35) : Qt.rgba(191/255, 90/255, 242/255, 0.2)
                        border.color: "#bf5af2"
                        border.width: 1

                        Text {
                            id: launchText
                            anchors.centerIn: parent
                            text: i18n("Launch")
                            font.family: "SF Hello"
                            font.pixelSize: 11
                            font.bold: true
                            color: "#bf5af2"
                        }

                        MouseArea {
                            id: launchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: termTabRoot.launchBackgroundTask(cmdInput.text)
                        }
                    }
                }

                // Logs View or Tasks List View
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // --- Subview A: Task Logs ---
                    ColumnLayout {
                        anchors.fill: parent
                        visible: termTabRoot.showLogs
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: i18n("Logs: %1", termTabRoot.currentLogUnit)
                                font.family: "SF Hello"
                                font.pixelSize: 11
                                font.bold: true
                                color: "#bf5af2"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                implicitWidth: closeLogTxt.implicitWidth + 12
                                implicitHeight: 22
                                radius: 4
                                color: closeLogM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)

                                Text {
                                    id: closeLogTxt
                                    anchors.centerIn: parent
                                    text: i18n("Back to Tasks")
                                    font.family: "SF Hello"
                                    font.pixelSize: 10
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    id: closeLogM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: termTabRoot.showLogs = false
                                }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                text: termTabRoot.currentLogText
                                readOnly: true
                                textFormat: TextEdit.PlainText
                                font.family: "Hack Nerd Font"
                                font.pixelSize: 10
                                color: "#d1d5db"
                                background: Rectangle {
                                    color: Qt.rgba(0, 0, 0, 0.4)
                                    radius: 6
                                    border.color: Qt.rgba(1, 1, 1, 0.08)
                                }
                            }
                        }
                    }

                    // --- Subview B: Tasks List ---
                    ListView {
                        id: taskListView
                        anchors.fill: parent
                        visible: !termTabRoot.showLogs
                        clip: true
                        spacing: 6
                        model: termTabRoot.bgTasks

                        delegate: Rectangle {
                            width: taskListView.width
                            implicitHeight: taskItemCol.implicitHeight + 12
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.04)
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            ColumnLayout {
                                id: taskItemCol
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    // Category status badge
                                    Rectangle {
                                        implicitWidth: catTxt.implicitWidth + 10
                                        implicitHeight: 18
                                        radius: 4
                                        color: modelData.statusCategory === "running" ? Qt.rgba(48/255, 209/255, 88/255, 0.2)
                                             : (modelData.statusCategory === "failed" ? Qt.rgba(255/255, 69/255, 58/255, 0.2)
                                             : Qt.rgba(1, 1, 1, 0.1))
                                        border.color: modelData.statusCategory === "running" ? "#30d158"
                                                    : (modelData.statusCategory === "failed" ? "#ff453a"
                                                    : Qt.rgba(1, 1, 1, 0.2))
                                        border.width: 1

                                        Text {
                                            id: catTxt
                                            anchors.centerIn: parent
                                            text: modelData.statusCategory === "running" ? i18n("RUNNING")
                                                : (modelData.statusCategory === "failed" ? i18n("FAILED")
                                                : (modelData.execStatus !== undefined ? i18n("EXIT %1", modelData.execStatus) : i18n("EXITED")))
                                            font.family: "SF Hello"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: modelData.statusCategory === "running" ? "#30d158"
                                                 : (modelData.statusCategory === "failed" ? "#ff453a"
                                                 : "#ffffff")
                                        }
                                    }

                                    Text {
                                        text: modelData.unit
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: 10
                                        color: "#ffffff"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Logs Action
                                    Rectangle {
                                        implicitWidth: logTxt.implicitWidth + 10
                                        implicitHeight: 20
                                        radius: 4
                                        color: logM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)

                                        Text {
                                            id: logTxt
                                            anchors.centerIn: parent
                                            text: i18n("Logs")
                                            font.family: "SF Hello"
                                            font.pixelSize: 10
                                            color: "#0a84ff"
                                        }

                                        MouseArea {
                                            id: logM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: termTabRoot.viewTaskLogs(modelData.unit)
                                        }
                                    }

                                    // Stop / Dismiss Action
                                    Rectangle {
                                        implicitWidth: actTxt.implicitWidth + 10
                                        implicitHeight: 20
                                        radius: 4
                                        readonly property bool isFinished: (modelData.statusCategory === "exited" || modelData.statusCategory === "failed")
                                        color: actM.containsMouse
                                               ? (isFinished ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1.0, 69/255, 58/255, 0.25))
                                               : (isFinished ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1.0, 69/255, 58/255, 0.15))

                                        Text {
                                            id: actTxt
                                            anchors.centerIn: parent
                                            text: (modelData.statusCategory === "exited" || modelData.statusCategory === "failed") ? i18n("Dismiss") : i18n("Stop")
                                            font.family: "SF Hello"
                                            font.pixelSize: 10
                                            color: (modelData.statusCategory === "exited" || modelData.statusCategory === "failed") ? Qt.rgba(1, 1, 1, 0.6) : "#ff453a"
                                        }

                                        MouseArea {
                                            id: actM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: termTabRoot.stopOrDismissTask(modelData.unit, (modelData.statusCategory === "exited" || modelData.statusCategory === "failed"))
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.description || ""
                                    font.family: "SF Hello"
                                    font.pixelSize: 10
                                    color: Qt.rgba(1, 1, 1, 0.4)
                                    visible: (modelData.description || "") !== ""
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Empty tasks state
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 40
                            height: 60
                            color: "transparent"
                            visible: termTabRoot.bgTasks.length === 0

                            Text {
                                anchors.centerIn: parent
                                text: i18n("No background tasks active.\nEnter a command above to launch.")
                                font.family: "SF Hello"
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.35)
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
