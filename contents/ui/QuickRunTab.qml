import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: termRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // --- State: Multi-Tab Sessions ---
    property var terminalTabs: [
        {
            id: 1,
            title: "Tab 1",
            currentDir: "/home/bgg",
            history: [
                {
                    type: "system",
                    text: i18n("Quick Terminal — Tab 1\nType a command or click 'Paste & Run'.")
                }
            ],
            cmdHistory: [],
            cmdHistoryIdx: -1
        }
    ]

    property int activeTabIndex: 0
    property bool isExecuting: false

    readonly property var activeTab: (terminalTabs && terminalTabs.length > activeTabIndex) ? terminalTabs[activeTabIndex] : null

    // Execution Engine via Plasma5Support
    Plasma5Support.DataSource {
        id: execEngine
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source);
            termRoot.isExecuting = false;

            if (!termRoot.activeTab) return;

            let fullOut = data["stdout"] || "";
            let fullErr = data["stderr"] || "";
            let code = data["exit code"] ?? 0;

            let parsedOut = fullOut;
            let newPwd = termRoot.activeTab.currentDir;

            if (fullOut.includes("__RAVEN_END__")) {
                let parts = fullOut.split("__RAVEN_END__");
                parsedOut = parts[0];
                let trailer = parts[1].trim();
                let lines = trailer.split("\n");
                if (lines.length >= 1) {
                    let c = parseInt(lines[0]);
                    if (!isNaN(c)) code = c;
                }
                if (lines.length >= 2) {
                    newPwd = lines[1].trim();
                }
            }

            let resultText = "";
            if (parsedOut.length > 0) resultText += parsedOut;
            if (fullErr.length > 0) {
                if (resultText.length > 0) resultText += "\n";
                resultText += fullErr;
            }

            if (resultText === "" && code === 0) {
                resultText = "(Command completed with exit code 0)";
            }

            // Append output to history
            let tabsCopy = termRoot.terminalTabs.slice();
            let tabCopy = Object.assign({}, tabsCopy[termRoot.activeTabIndex]);
            let histCopy = tabCopy.history.slice();

            histCopy.push({
                type: "output",
                text: resultText.trim(),
                exitCode: code
            });

            tabCopy.history = histCopy;
            tabCopy.currentDir = newPwd;
            tabsCopy[termRoot.activeTabIndex] = tabCopy;
            termRoot.terminalTabs = tabsCopy;

            outputList.positionViewAtEnd();
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
                if (clip.length > 0) {
                    cmdInput.text = clip;
                    termRoot.executeCommand(clip);
                }
            }
        }
    }

    // Actions
    function executeCommand(cmd) {
        if (!cmd || cmd.trim() === "" || !activeTab) return;
        cmd = cmd.trim();

        // 1. Append command to display history
        let tabsCopy = terminalTabs.slice();
        let tabCopy = Object.assign({}, tabsCopy[activeTabIndex]);
        let histCopy = tabCopy.history.slice();
        let cmdHistCopy = tabCopy.cmdHistory.slice();

        histCopy.push({
            type: "input",
            text: tabCopy.currentDir.replace("/home/bgg", "~") + " ❯ " + cmd
        });
        cmdHistCopy.push(cmd);

        tabCopy.history = histCopy;
        tabCopy.cmdHistory = cmdHistCopy;
        tabCopy.cmdHistoryIdx = -1;
        tabsCopy[activeTabIndex] = tabCopy;
        terminalTabs = tabsCopy;

        cmdInput.text = "";
        isExecuting = true;
        outputList.positionViewAtEnd();

        // 2. Dispatch command through bash
        let escapedCmd = cmd.replace(/'/g, "'\\''");
        let wrapper = "cd '" + tabCopy.currentDir + "' ; eval '" + escapedCmd + "' ; echo '__RAVEN_END__$?' ; pwd";
        execEngine.connectSource(wrapper);
    }

    function pasteAndExecute() {
        clipEngine.connectSource("wl-paste");
    }

    function clearCurrentTab() {
        if (!activeTab) return;
        let tabsCopy = terminalTabs.slice();
        let tabCopy = Object.assign({}, tabsCopy[activeTabIndex]);
        tabCopy.history = [
            {
                type: "system",
                text: i18n("Terminal buffer cleared.")
            }
        ];
        tabsCopy[activeTabIndex] = tabCopy;
        terminalTabs = tabsCopy;
    }

    function addTab() {
        let nextId = terminalTabs.length + 1;
        let tabsCopy = terminalTabs.slice();
        tabsCopy.push({
            id: nextId,
            title: "Tab " + nextId,
            currentDir: "/home/bgg",
            history: [
                {
                    type: "system",
                    text: i18n("Quick Terminal — Tab %1", nextId)
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

        // --- Row 1: Terminal Tab Bar ([ Tab 1 ] [ Tab 2 ] [ + ]) ---
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
                                source: "utilities-terminal"
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

        // --- Row 2: Action Buttons ([ 📋 Paste & Run ] [ ▶ Run ] [ 🧹 Clear ]) ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Paste & Run
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
                        text: i18n("Paste & Run")
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
                    onClicked: termRoot.pasteAndExecute()
                }
            }

            // Execute
            Rectangle {
                implicitWidth: runTxt.implicitWidth + 20
                height: 30
                radius: 8
                color: runM.containsMouse ? Qt.rgba(48/255, 209/255, 88/255, 0.3) : Qt.rgba(48/255, 209/255, 88/255, 0.15)
                border.color: "#30d158"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Kirigami.Icon {
                        source: "system-run"
                        implicitWidth: 13
                        implicitHeight: 13
                        color: "#30d158"
                    }
                    Text {
                        id: runTxt
                        text: i18n("Run")
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#30d158"
                    }
                }

                MouseArea {
                    id: runM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: termRoot.executeCommand(cmdInput.text)
                }
            }

            // Clear
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

        // --- Current Directory Indicator ---
        Rectangle {
            Layout.fillWidth: true
            height: 22
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
                    text: termRoot.activeTab ? termRoot.activeTab.currentDir.replace("/home/bgg", "~") : "~"
                    font.family: "SF Mono"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.5)
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
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

        // --- Terminal Output Buffer (Selectable, Scrollable) ---
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
                spacing: 6
                model: termRoot.activeTab ? termRoot.activeTab.history : []

                ScrollBar.vertical: ScrollBar {
                    active: true
                }

                delegate: Item {
                    width: outputList.width
                    implicitHeight: contentTxt.implicitHeight

                    TextEdit {
                        id: contentTxt
                        width: parent.width
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
                }
            }
        }

        // --- Terminal Input Bar at Bottom ---
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
                        termRoot.executeCommand(text);
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
                        onClicked: termRoot.executeCommand(cmdInput.text)
                    }
                }
            }
        }
    }
}
