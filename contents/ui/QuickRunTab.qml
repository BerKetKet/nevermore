import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: termRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property string userHome: String(StandardPaths.writableLocation(StandardPaths.HomeLocation)).replace(/^file:\/\//, "")
    property int tabCounter: 1
    property int timeoutSeconds: 30

    function formatPath(p) {
        if (!p) return "~";
        if (p === userHome) return "~";
        if (p.startsWith(userHome + "/")) return "~" + p.substring(userHome.length);
        return p;
    }

    function base64Encode(str) {
        let bytes = [];
        for (let i = 0; i < str.length; i++) {
            let code = str.charCodeAt(i);
            if (code < 0x80) {
                bytes.push(code);
            } else if (code < 0x800) {
                bytes.push(0xc0 | (code >> 6));
                bytes.push(0x80 | (code & 0x3f));
            } else if (code < 0xd800 || code >= 0xe000) {
                bytes.push(0xe0 | (code >> 12));
                bytes.push(0x80 | ((code >> 6) & 0x3f));
                bytes.push(0x80 | (code & 0x3f));
            } else {
                i++;
                code = 0x10000 + (((code & 0x3ff) << 10) | (str.charCodeAt(i) & 0x3ff));
                bytes.push(0xf0 | (code >> 18));
                bytes.push(0x80 | ((code >> 12) & 0x3f));
                bytes.push(0x80 | ((code >> 6) & 0x3f));
                bytes.push(0x80 | (code & 0x3f));
            }
        }
        return Qt.btoa(new Uint8Array(bytes).buffer);
    }

    function generateSentinel() {
        let chars = "0123456789abcdef";
        let res = "NVRM_";
        for (let i = 0; i < 16; i++) {
            res += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return res;
    }

    // --- State: Multi-Tab Sessions ---
    property var terminalTabs: [
        {
            id: 1,
            title: i18n("Tab 1"),
            currentDir: userHome,
            history: [
                {
                    type: "system",
                    text: i18n("Nevermore Quick Run — Tab 1\nType a command or paste from clipboard.")
                }
            ],
            cmdHistory: [],
            cmdHistoryIdx: -1
        }
    ]

    property int activeTabIndex: 0
    property bool isExecuting: false
    property string currentSentinel: ""
    property string runningSource: ""
    property int runningTabId: -1

    readonly property var activeTab: (terminalTabs && terminalTabs.length > activeTabIndex) ? terminalTabs[activeTabIndex] : null

    // Background Tasks State
    property var bgTasks: []
    property bool tasksExpanded: false
    readonly property bool isActuallyVisible: visible && (Window.window ? (Window.window.visible && Window.window.visibility !== Window.Hidden) : true)

    Timer {
        id: taskPollTimer
        interval: 3000
        repeat: true
        running: termRoot.isActuallyVisible
        onTriggered: termRoot.pollTasks()
    }

    Timer {
        id: taskRefreshTimer
        interval: 350
        repeat: false
        onTriggered: termRoot.pollTasks()
    }

    onIsActuallyVisibleChanged: {
        if (isActuallyVisible) {
            termRoot.pollTasks();
        }
    }

    // Execution Engine via Plasma5Support
    Plasma5Support.DataSource {
        id: execEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            if (source !== termRoot.runningSource) return;

            disconnectSource(source);
            termRoot.runningSource = "";
            termRoot.isExecuting = false;

            if (!termRoot.activeTab) return;

            let fullOut = data["stdout"] || "";
            let fullErr = data["stderr"] || "";
            let exitCode = data["exit code"] ?? 0;
            let sentinel = termRoot.currentSentinel;

            let parsedOut = fullOut;
            let newPwd = termRoot.activeTab.currentDir;

            if (sentinel !== "" && fullOut.indexOf(sentinel) !== -1) {
                let tokenMarker = "\n" + sentinel + "\n";
                let idx = fullOut.lastIndexOf(tokenMarker);
                if (idx === -1) {
                    idx = fullOut.lastIndexOf(sentinel);
                    tokenMarker = sentinel;
                }

                if (idx !== -1) {
                    parsedOut = fullOut.substring(0, idx);
                    let trailer = fullOut.substring(idx + tokenMarker.length).trim();
                    let lines = trailer.split("\n");
                    if (lines.length >= 1) {
                        let c = parseInt(lines[0], 10);
                        if (!isNaN(c)) exitCode = c;
                    }
                    if (lines.length >= 2) {
                        let p = lines.slice(1).join("\n").trim();
                        if (p.length > 0) newPwd = p;
                    }
                }
            }

            let resultText = "";
            if (parsedOut.length > 0) resultText += parsedOut;
            if (fullErr.length > 0) {
                if (resultText.length > 0) resultText += "\n";
                resultText += fullErr;
            }

            if (resultText.trim() === "" && exitCode === 0) {
                resultText = i18n("(Command completed successfully with exit code 0)");
            }

            let isTimeout = (exitCode === 124);

            // Append output to the originating tab history
            let tabsCopy = termRoot.terminalTabs.slice();
            let targetIdx = -1;
            for (let i = 0; i < tabsCopy.length; i++) {
                if (tabsCopy[i].id === termRoot.runningTabId) {
                    targetIdx = i;
                    break;
                }
            }
            if (targetIdx === -1) {
                targetIdx = termRoot.activeTabIndex;
            }

            let tabCopy = Object.assign({}, tabsCopy[targetIdx]);
            let histCopy = tabCopy.history.slice();

            histCopy.push({
                type: "output",
                text: resultText.trim(),
                exitCode: exitCode,
                isTimeout: isTimeout,
                cwd: newPwd
            });

            tabCopy.history = histCopy;
            tabCopy.currentDir = newPwd;
            tabsCopy[targetIdx] = tabCopy;
            termRoot.terminalTabs = tabsCopy;

            if (targetIdx === termRoot.activeTabIndex) {
                outputList.positionViewAtEnd();
            }
            termRoot.runningTabId = -1;
        }
    }

    // Helper Engine for Stop and Background launch
    Plasma5Support.DataSource {
        id: helperEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
        }
    }

    // Clipboard Reader Engine
    Plasma5Support.DataSource {
        id: clipEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            if (source === "wl-paste") {
                let clip = data["stdout"] || "";
                clip = clip.trim();
                if (clip.length === 0) return;

                if (clip.indexOf("\n") !== -1 || clip.indexOf("\r") !== -1) {
                    confirmDialog.pendingText = clip;
                    confirmDialog.visible = true;
                } else {
                    cmdInput.text = clip;
                }
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
                    termRoot.bgTasks = parsed;
                    if (parsed.length > 0 && !termRoot.tasksExpanded) {
                        termRoot.tasksExpanded = true;
                    }
                }
            } catch (e) {
                // Not JSON or parse error
            }
        }
    }

    // Task Actions Engine (Logs / Output)
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

                if (termRoot.activeTab) {
                    let tabsCopy = termRoot.terminalTabs.slice();
                    let tabCopy = Object.assign({}, tabsCopy[termRoot.activeTabIndex]);
                    let histCopy = tabCopy.history.slice();

                    histCopy.push({
                        type: "system",
                        text: "=== " + source + " ===\n" + combined
                    });

                    tabCopy.history = histCopy;
                    tabsCopy[termRoot.activeTabIndex] = tabCopy;
                    termRoot.terminalTabs = tabsCopy;
                    outputList.positionViewAtEnd();
                }
            }
        }
    }

    // Actions
    function executeCommand(cmd, asBackground) {
        if (!cmd || cmd.trim() === "" || !activeTab || isExecuting) return;
        cmd = cmd.trim();

        let tabsCopy = terminalTabs.slice();
        let tabCopy = Object.assign({}, tabsCopy[activeTabIndex]);
        let histCopy = tabCopy.history.slice();
        let cmdHistCopy = tabCopy.cmdHistory.slice();

        histCopy.push({
            type: "input",
            text: formatPath(tabCopy.currentDir) + " ❯ " + (asBackground ? "[bg] " : "") + cmd
        });
        cmdHistCopy.push(cmd);

        tabCopy.history = histCopy;
        tabCopy.cmdHistory = cmdHistCopy;
        tabCopy.cmdHistoryIdx = -1;
        tabsCopy[activeTabIndex] = tabCopy;
        terminalTabs = tabsCopy;

        runningTabId = activeTab ? activeTab.id : -1;
        cmdInput.text = "";
        isExecuting = true;
        outputList.positionViewAtEnd();

        currentSentinel = generateSentinel();
        let b64Cwd = base64Encode(tabCopy.currentDir);
        let b64Cmd = base64Encode(cmd);
        let runnerPath = userHome + "/.local/bin/nevermore-run";

        let fullCommand = "";
        if (asBackground) {
            fullCommand = "\"" + runnerPath + "\" --bg " + currentSentinel + " " + b64Cwd + " " + b64Cmd;
            taskRefreshTimer.restart();
        } else {
            fullCommand = "\"" + runnerPath + "\" " + currentSentinel + " " + b64Cwd + " " + b64Cmd + " " + timeoutSeconds;
        }

        runningSource = fullCommand;
        execEngine.connectSource(fullCommand);
    }

    function stopCommand() {
        if (!isExecuting) return;

        let sentinel = currentSentinel;
        let runnerPath = userHome + "/.local/bin/nevermore-run";
        helperEngine.connectSource("\"" + runnerPath + "\" --stop " + sentinel);

        if (runningSource !== "") {
            execEngine.disconnectSource(runningSource);
            runningSource = "";
        }
        isExecuting = false;

        let tabsCopy = terminalTabs.slice();
        let targetIdx = -1;
        for (let i = 0; i < tabsCopy.length; i++) {
            if (tabsCopy[i].id === termRoot.runningTabId) {
                targetIdx = i;
                break;
            }
        }
        if (targetIdx === -1) {
            targetIdx = activeTabIndex;
        }

        if (targetIdx >= 0 && targetIdx < tabsCopy.length) {
            let tabCopy = Object.assign({}, tabsCopy[targetIdx]);
            let histCopy = tabCopy.history.slice();

            histCopy.push({
                type: "output",
                text: i18n("Command stopped by user."),
                exitCode: 130,
                isTimeout: false,
                cwd: tabCopy.currentDir
            });

            tabCopy.history = histCopy;
            tabsCopy[targetIdx] = tabCopy;
            terminalTabs = tabsCopy;
            if (targetIdx === activeTabIndex) {
                outputList.positionViewAtEnd();
            }
        }
        termRoot.runningTabId = -1;
    }

    function openInKonsole(dir) {
        let targetDir = dir || (activeTab ? activeTab.currentDir : userHome);
        let escapedDir = targetDir.replace(/'/g, "'\\''");
        helperEngine.connectSource("setsid -f konsole --workdir '" + escapedDir + "' </dev/null >/dev/null 2>&1");
    }

    function pasteClipboard() {
        clipEngine.connectSource("wl-paste");
    }

    function pollTasks() {
        taskPollEngine.connectSource("systemctl --user list-units \"nevermore-task-*\" --output=json");
    }

    function viewTaskLogs(unit) {
        if (!unit) return;
        taskActionEngine.connectSource("journalctl --user -u " + unit + " -n 200 --no-pager");
    }

    function stopTask(unit) {
        if (!unit) return;
        helperEngine.connectSource("systemctl --user stop " + unit);
        taskRefreshTimer.restart();
    }

    function clearCurrentTab() {
        if (!activeTab) return;
        let tabsCopy = terminalTabs.slice();
        let tabCopy = Object.assign({}, tabsCopy[activeTabIndex]);
        tabCopy.history = [
            {
                type: "system",
                text: i18n("Buffer cleared.")
            }
        ];
        tabsCopy[activeTabIndex] = tabCopy;
        terminalTabs = tabsCopy;
    }

    function addTab() {
        let nextId = ++tabCounter;
        let tabsCopy = terminalTabs.slice();
        tabsCopy.push({
            id: nextId,
            title: i18n("Tab %1", nextId),
            currentDir: userHome,
            history: [
                {
                    type: "system",
                    text: i18n("Nevermore Quick Run — Tab %1", nextId)
                }
            ],
            cmdHistory: [],
            cmdHistoryIdx: -1
        });
        terminalTabs = tabsCopy;
        activeTabIndex = terminalTabs.length - 1;
    }

    function closeTab(index) {
        if (terminalTabs.length <= 1) return;
        let tabsCopy = terminalTabs.slice();
        tabsCopy.splice(index, 1);
        terminalTabs = tabsCopy;
        if (activeTabIndex >= terminalTabs.length) {
            activeTabIndex = terminalTabs.length - 1;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // --- Row 1: Tab Bar ([ Tab 1 ] [ Tab 2 ] [ + ]) ---
        ScrollView {
            Layout.fillWidth: true
            implicitHeight: 32
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            RowLayout {
                spacing: 6

                Repeater {
                    model: termRoot.terminalTabs

                    Rectangle {
                        implicitWidth: tabLabel.implicitWidth + (termRoot.terminalTabs.length > 1 ? 34 : 20)
                        implicitHeight: 28
                        radius: 8
                        color: termRoot.activeTabIndex === index ? Qt.rgba(1, 1, 1, 0.18) : (tabM.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                        border.color: termRoot.activeTabIndex === index ? "#0a84ff" : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Kirigami.Icon {
                                source: "system-run"
                                implicitWidth: 12
                                implicitHeight: 12
                                color: termRoot.activeTabIndex === index ? "#0a84ff" : Qt.rgba(1, 1, 1, 0.5)
                            }

                            Text {
                                id: tabLabel
                                text: modelData.title
                                font.family: "SF Hello"
                                font.pixelSize: 11
                                font.bold: termRoot.activeTabIndex === index
                                color: termRoot.activeTabIndex === index ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                            }

                            // Close X
                            Rectangle {
                                implicitWidth: 14
                                implicitHeight: 14
                                radius: 7
                                color: closeM.containsMouse ? Qt.rgba(1.0, 69/255, 58/255, 0.3) : "transparent"
                                visible: termRoot.terminalTabs.length > 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 9
                                    color: closeM.containsMouse ? "#ff453a" : Qt.rgba(1, 1, 1, 0.5)
                                }

                                MouseArea {
                                    id: closeM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: termRoot.closeTab(index)
                                }
                            }
                        }

                        MouseArea {
                            id: tabM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: termRoot.activeTabIndex = index
                        }
                    }
                }

                // New Tab Button (+)
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 8
                    color: addM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#0a84ff"
                    }

                    MouseArea {
                        id: addM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: termRoot.addTab()
                    }
                }
            }
        }

        // --- Row 2: Action Buttons ([ 📋 Paste ] [ ▶ Run / ■ Stop ] [ ⚙ Bg ] [ 🧹 Clear ]) ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Paste Button
            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 8
                color: pasteM.containsMouse ? "#006ee6" : "#0a84ff"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Kirigami.Icon {
                        source: "edit-paste"
                        implicitWidth: 14
                        implicitHeight: 14
                        color: "#ffffff"
                    }
                    Text {
                        text: i18n("Paste")
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#ffffff"
                    }
                }

                MouseArea {
                    id: pasteM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: termRoot.pasteClipboard()
                }
            }

            // Run / Stop Button
            Rectangle {
                implicitWidth: runTxt.implicitWidth + 24
                height: 30
                radius: 8
                color: termRoot.isExecuting
                       ? (stopM.containsMouse ? Qt.rgba(1.0, 69/255, 58/255, 0.4) : Qt.rgba(1.0, 69/255, 58/255, 0.2))
                       : (runM.containsMouse ? Qt.rgba(48/255, 209/255, 88/255, 0.3) : Qt.rgba(48/255, 209/255, 88/255, 0.15))
                border.color: termRoot.isExecuting ? "#ff453a" : "#30d158"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Kirigami.Icon {
                        source: termRoot.isExecuting ? "process-stop" : "system-run"
                        implicitWidth: 13
                        implicitHeight: 13
                        color: termRoot.isExecuting ? "#ff453a" : "#30d158"
                    }
                    Text {
                        id: runTxt
                        text: termRoot.isExecuting ? i18n("Stop") : i18n("Run")
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        font.bold: true
                        color: termRoot.isExecuting ? "#ff453a" : "#30d158"
                    }
                }

                MouseArea {
                    id: runM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (termRoot.isExecuting) {
                            termRoot.stopCommand();
                        } else {
                            termRoot.executeCommand(cmdInput.text, false);
                        }
                    }
                }

                MouseArea {
                    id: stopM
                    anchors.fill: parent
                    enabled: termRoot.isExecuting
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: termRoot.stopCommand()
                }
            }

            // Background Task Button
            Rectangle {
                implicitWidth: bgTxt.implicitWidth + 20
                height: 30
                radius: 8
                color: bgM.containsMouse ? Qt.rgba(191/255, 90/255, 242/255, 0.25) : Qt.rgba(1, 1, 1, 0.06)
                border.color: bgM.containsMouse ? "#bf5af2" : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Kirigami.Icon {
                        source: "system-switch-user"
                        implicitWidth: 13
                        implicitHeight: 13
                        color: bgM.containsMouse ? "#bf5af2" : Qt.rgba(1, 1, 1, 0.7)
                    }
                    Text {
                        id: bgTxt
                        text: i18n("Bg Task")
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        font.bold: true
                        color: bgM.containsMouse ? "#bf5af2" : Qt.rgba(1, 1, 1, 0.8)
                    }
                }

                MouseArea {
                    id: bgM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: termRoot.executeCommand(cmdInput.text, true)
                }
            }

            // Clear Button
            Rectangle {
                implicitWidth: clearTxt.implicitWidth + 20
                height: 30
                radius: 8
                color: clearM.containsMouse ? Qt.rgba(1.0, 69/255, 58/255, 0.25) : Qt.rgba(1, 1, 1, 0.06)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Kirigami.Icon {
                        source: "edit-clear"
                        implicitWidth: 13
                        implicitHeight: 13
                        color: clearM.containsMouse ? "#ff453a" : Qt.rgba(1, 1, 1, 0.7)
                    }
                    Text {
                        id: clearTxt
                        text: i18n("Clear")
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        font.bold: true
                        color: clearM.containsMouse ? "#ff453a" : Qt.rgba(1, 1, 1, 0.8)
                    }
                }

                MouseArea {
                    id: clearM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: termRoot.clearCurrentTab()
                }
            }
        }

        // --- Current Directory & Konsole Launcher Row ---
        Rectangle {
            Layout.fillWidth: true
            height: 24
            radius: 6
            color: Qt.rgba(1, 1, 1, 0.03)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 6

                Kirigami.Icon {
                    source: "folder"
                    implicitWidth: 11
                    implicitHeight: 11
                    color: Qt.rgba(1, 1, 1, 0.4)
                }

                Text {
                    text: termRoot.activeTab ? termRoot.formatPath(termRoot.activeTab.currentDir) : "~"
                    font.family: "SF Mono"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.6)
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                // Open in Konsole Link/Button
                Rectangle {
                    implicitWidth: konsoleTxt.implicitWidth + 14
                    height: 18
                    radius: 4
                    color: konsoleM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Kirigami.Icon {
                            source: "utilities-terminal"
                            implicitWidth: 10
                            implicitHeight: 10
                            color: "#0a84ff"
                        }
                        Text {
                            id: konsoleTxt
                            text: i18n("Open in Konsole")
                            font.family: "SF Hello"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#0a84ff"
                        }
                    }

                    MouseArea {
                        id: konsoleM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: termRoot.openInKonsole()
                    }
                }

                Text {
                    text: termRoot.isExecuting ? i18n("Running...") : i18n("Idle")
                    font.family: "SF Hello"
                    font.pixelSize: 10
                    font.bold: true
                    color: termRoot.isExecuting ? "#ff9f0a" : "#30d158"
                }
            }
        }

        // --- Background Tasks Section ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tasksSectionCol.implicitHeight + (termRoot.tasksExpanded ? 12 : 8)
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.04)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            clip: true

            ColumnLayout {
                id: tasksSectionCol
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                // Header: [ Icon ] Background Tasks (count) [ chevron ]
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Kirigami.Icon {
                        source: "system-switch-user"
                        implicitWidth: 14
                        implicitHeight: 14
                        color: "#bf5af2"
                    }

                    Text {
                        text: i18n("Background Tasks (%1)", termRoot.bgTasks.length)
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        font.bold: true
                        color: termRoot.bgTasks.length > 0 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                        Layout.fillWidth: true
                    }

                    Text {
                        text: termRoot.tasksExpanded ? "▲" : "▼"
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: termRoot.tasksExpanded = !termRoot.tasksExpanded
                    }
                }

                // Expanded view
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: termRoot.tasksExpanded
                    spacing: 4

                    Text {
                        visible: termRoot.bgTasks.length === 0
                        text: i18n("No background tasks running.")
                        font.family: "SF Hello"
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.4)
                        Layout.leftMargin: 4
                        Layout.topMargin: 2
                    }

                    Repeater {
                        model: termRoot.bgTasks

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.06)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 6

                                // Unit name
                                Text {
                                    text: modelData.unit ? modelData.unit.replace(/^nevermore-task-/, "").replace(/\.service$/, "") : ""
                                    font.family: "SF Mono"
                                    font.pixelSize: 10
                                    color: "#ffffff"
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                // State badge
                                Rectangle {
                                    implicitWidth: stateTxt.implicitWidth + 8
                                    height: 16
                                    radius: 4
                                    color: modelData.sub === "running" ? Qt.rgba(48/255, 209/255, 88/255, 0.2) : Qt.rgba(1, 1, 1, 0.1)
                                    border.color: modelData.sub === "running" ? "#30d158" : Qt.rgba(1, 1, 1, 0.2)
                                    border.width: 1

                                    Text {
                                        id: stateTxt
                                        anchors.centerIn: parent
                                        text: modelData.sub || modelData.active || "unknown"
                                        font.family: "SF Hello"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: modelData.sub === "running" ? "#30d158" : Qt.rgba(1, 1, 1, 0.7)
                                    }
                                }

                                // Logs Button
                                Rectangle {
                                    implicitWidth: logsTxt.implicitWidth + 10
                                    height: 20
                                    radius: 4
                                    color: logsM.containsMouse ? Qt.rgba(10/255, 132/255, 1.0, 0.3) : Qt.rgba(10/255, 132/255, 1.0, 0.15)
                                    border.color: "#0a84ff"
                                    border.width: 1

                                    Text {
                                        id: logsTxt
                                        anchors.centerIn: parent
                                        text: i18n("Logs")
                                        font.family: "SF Hello"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: "#0a84ff"
                                    }

                                    MouseArea {
                                        id: logsM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: termRoot.viewTaskLogs(modelData.unit)
                                    }
                                }

                                // Stop Button
                                Rectangle {
                                    implicitWidth: stopTaskTxt.implicitWidth + 10
                                    height: 20
                                    radius: 4
                                    color: stopTaskM.containsMouse ? Qt.rgba(1.0, 69/255, 58/255, 0.3) : Qt.rgba(1.0, 69/255, 58/255, 0.15)
                                    border.color: "#ff453a"
                                    border.width: 1

                                    Text {
                                        id: stopTaskTxt
                                        anchors.centerIn: parent
                                        text: i18n("Stop")
                                        font.family: "SF Hello"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: "#ff453a"
                                    }

                                    MouseArea {
                                        id: stopTaskM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: termRoot.stopTask(modelData.unit)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Output Buffer Area ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: "#0d0d10"
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            clip: true

            ListView {
                id: outputList
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                model: termRoot.activeTab ? termRoot.activeTab.history : []

                ScrollBar.vertical: ScrollBar {
                    active: true
                }

                delegate: ColumnLayout {
                    width: outputList.width
                    spacing: 4

                    // Output Text Area
                    TextEdit {
                        id: contentTxt
                        Layout.fillWidth: true
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        font.family: "SF Mono"
                        font.pixelSize: 11

                        color: {
                            if (modelData.type === "input") return "#30d158";
                            if (modelData.type === "system") return "#8e8e93";
                            if (modelData.exitCode && modelData.exitCode !== 0) return "#ff453a";
                            return "#f2f2f7";
                        }

                        font.bold: modelData.type === "input"
                        text: modelData.text || ""
                    }

                    // Exit Code Badge and Failure Tag
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: modelData.type === "output" && modelData.exitCode !== undefined

                        Rectangle {
                            implicitWidth: exitBadgeText.implicitWidth + 10
                            height: 18
                            radius: 4
                            color: modelData.exitCode === 0 ? Qt.rgba(48/255, 209/255, 88/255, 0.15) : Qt.rgba(1.0, 69/255, 58/255, 0.2)
                            border.color: modelData.exitCode === 0 ? "#30d158" : "#ff453a"
                            border.width: 1

                            Text {
                                id: exitBadgeText
                                anchors.centerIn: parent
                                text: (modelData && modelData.exitCode !== undefined) ? (modelData.exitCode === 0 ? i18n("Exit 0") : i18n("Exit %1", String(modelData.exitCode))) : ""
                                font.family: "SF Mono"
                                font.pixelSize: 10
                                font.bold: true
                                color: modelData.exitCode === 0 ? "#30d158" : "#ff453a"
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Timeout Hint Box
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: timeoutCol.implicitHeight + 16
                        radius: 8
                        color: Qt.rgba(1.0, 159/255, 10/255, 0.12)
                        border.color: "#ff9f0a"
                        border.width: 1
                        visible: modelData.isTimeout === true

                        ColumnLayout {
                            id: timeoutCol
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            RowLayout {
                                spacing: 6
                                Kirigami.Icon {
                                    source: "dialog-warning"
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    color: "#ff9f0a"
                                }
                                Text {
                                    text: i18n("Command may need an interactive terminal")
                                    font.family: "SF Hello"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#ff9f0a"
                                }
                            }

                            Text {
                                text: i18n("The command ran past the %1 second timeout. If it is expecting keyboard input or full TTY control, run it in a full terminal window.", termRoot.timeoutSeconds)
                                font.family: "SF Hello"
                                font.pixelSize: 11
                                color: "#f2f2f7"
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }

                            Button {
                                text: i18n("Open in Konsole")
                                icon.name: "utilities-terminal"
                                onClicked: termRoot.openInKonsole(modelData.cwd)
                            }
                        }
                    }
                }
            }
        }

        // --- Command Input Bar at Bottom ---
        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.06)
            border.color: cmdInput.activeFocus ? "#0a84ff" : Qt.rgba(1, 1, 1, 0.1)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 4
                spacing: 6

                Text {
                    text: "❯"
                    font.family: "SF Mono"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#0a84ff"
                }

                TextField {
                    id: cmdInput
                    Layout.fillWidth: true
                    placeholderText: i18n("Command... (Enter to run)")
                    font.family: "SF Mono"
                    font.pixelSize: 11
                    color: "#ffffff"
                    background: null
                    focus: true

                    onAccepted: {
                        termRoot.executeCommand(text, false);
                    }

                    Keys.onUpPressed: {
                        if (!termRoot.activeTab) return;
                        let hist = termRoot.activeTab.cmdHistory;
                        if (hist.length === 0) return;
                        let idx = termRoot.activeTab.cmdHistoryIdx;
                        if (idx === -1) idx = hist.length - 1;
                        else if (idx > 0) idx--;

                        termRoot.activeTab.cmdHistoryIdx = idx;
                        text = hist[idx];
                    }

                    Keys.onDownPressed: {
                        if (!termRoot.activeTab) return;
                        let hist = termRoot.activeTab.cmdHistory;
                        let idx = termRoot.activeTab.cmdHistoryIdx;
                        if (idx !== -1 && idx < hist.length - 1) {
                            idx++;
                            termRoot.activeTab.cmdHistoryIdx = idx;
                            text = hist[idx];
                        } else {
                            termRoot.activeTab.cmdHistoryIdx = -1;
                            text = "";
                        }
                    }
                }

                // Send Icon Button
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 6
                    color: sendM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)

                    Text {
                        anchors.centerIn: parent
                        text: "⏎"
                        font.pixelSize: 13
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: sendM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: termRoot.executeCommand(cmdInput.text, false)
                    }
                }
            }
        }
    }

    // --- Multiline Paste Confirmation Overlay ---
    Rectangle {
        id: confirmDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)
        visible: false
        z: 100

        property string pendingText: ""

        // Truly modal: MouseArea absorbs all pointer events so background cannot be clicked
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            acceptedButtons: Qt.AllButtons
            onClicked: (mouse) => mouse.accepted = true
            onPressed: (mouse) => mouse.accepted = true
            onReleased: (mouse) => mouse.accepted = true
            onDoubleClicked: (mouse) => mouse.accepted = true
            onWheel: (wheel) => wheel.accepted = true
        }

        // Trap keyboard focus
        focus: visible
        Keys.onEscapePressed: {
            confirmDialog.visible = false;
            confirmDialog.pendingText = "";
            cmdInput.forceActiveFocus();
        }

        onVisibleChanged: {
            if (visible) {
                runModalBtn.forceActiveFocus();
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 24, 360)
            implicitHeight: modalCol.implicitHeight + 24
            radius: 12
            color: "#1c1c1e"
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            // Absorb pointer clicks on the dialog itself
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => mouse.accepted = true
            }

            ColumnLayout {
                id: modalCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    spacing: 8
                    Kirigami.Icon {
                        source: "dialog-warning"
                        implicitWidth: 20
                        implicitHeight: 20
                        color: "#ff9f0a"
                    }
                    Text {
                        text: i18n("Multiline Clipboard Content")
                        font.family: "SF Hello"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#ffffff"
                    }
                }

                Text {
                    text: i18n("The pasted text contains multiple lines. Execute with bash or cancel:")
                    font.family: "SF Hello"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.7)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(140, previewText.implicitHeight + 12)
                    radius: 6
                    color: "#000000"
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    clip: true

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 6
                        TextEdit {
                            id: previewText
                            width: parent.width
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            font.family: "SF Mono"
                            font.pixelSize: 10
                            color: "#30d158"
                            text: confirmDialog.pendingText
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        id: cancelModalBtn
                        Layout.fillWidth: true
                        text: i18n("Cancel")
                        onClicked: {
                            confirmDialog.visible = false;
                            confirmDialog.pendingText = "";
                            cmdInput.forceActiveFocus();
                        }
                    }

                    Button {
                        id: runModalBtn
                        Layout.fillWidth: true
                        text: i18n("Run")
                        highlighted: true
                        focus: true
                        onClicked: {
                            let toRun = confirmDialog.pendingText;
                            confirmDialog.visible = false;
                            confirmDialog.pendingText = "";
                            termRoot.executeCommand(toRun, false);
                        }
                    }
                }
            }
        }
    }
}
