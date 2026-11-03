import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

// Candidate 1: Native Qt6 QMLTermWidget
import QMLTermWidget 2.0

PlasmoidItem {
    id: spikeRoot

    preferredRepresentation: fullRepresentation
    width: 600
    height: 700

    property string tmuxSocket: "nevermore"
    property string tmuxSession: "term"
    property string tmuxConfPath: ""
    property int selectedCandidate: 0 // 0: QMLTermWidget (Qt6), 1: Pure QML (capture-pane)
    property string candidate2Output: ""

    Plasma5Support.DataSource {
        id: execEngine
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source.indexOf("capture-pane") !== -1) {
                spikeRoot.candidate2Output = data.stdout || "";
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 150
        repeat: true
        running: spikeRoot.selectedCandidate === 1 && spikeRoot.visible
        onTriggered: {
            execEngine.connectSource("tmux -L " + spikeRoot.tmuxSocket + " capture-pane -t " + spikeRoot.tmuxSession + " -p");
        }
    }

    function openInKonsole() {
        execEngine.connectSource("konsole -e tmux -L " + spikeRoot.tmuxSocket + " attach -t " + spikeRoot.tmuxSession);
    }

    function sendKeyToTmux(key) {
        execEngine.connectSource("tmux -L " + spikeRoot.tmuxSocket + " send-keys -t " + spikeRoot.tmuxSession + " " + key);
    }

    fullRepresentation: Rectangle {
        anchors.fill: parent
        color: "#18181b"
        radius: 12
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Header bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Kirigami.Icon {
                    source: "utilities-terminal"
                    implicitWidth: 20
                    implicitHeight: 20
                    color: "#0a84ff"
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: i18n("Nevermore Terminal Spike (POC)")
                        font.family: "SF Hello"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#ffffff"
                    }
                    Text {
                        text: "tmux -L " + spikeRoot.tmuxSocket + " (session: " + spikeRoot.tmuxSession + ")"
                        font.family: "SF Mono"
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: i18n("Open in Konsole")
                    icon.name: "konsole"
                    onClicked: spikeRoot.openInKonsole()
                }
            }

            // Candidate Selector Tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Button {
                    Layout.fillWidth: true
                    text: i18n("Candidate 1: QMLTermWidget (Native Qt6)")
                    highlighted: spikeRoot.selectedCandidate === 0
                    onClicked: spikeRoot.selectedCandidate = 0
                }

                Button {
                    Layout.fillWidth: true
                    text: i18n("Candidate 2: Pure QML (capture-pane)")
                    highlighted: spikeRoot.selectedCandidate === 1
                    onClicked: spikeRoot.selectedCandidate = 1
                }
            }

            // Terminal Viewport
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: spikeRoot.selectedCandidate

                // Candidate 1: QMLTermWidget
                Rectangle {
                    color: "#0c0c0e"
                    radius: 8
                    clip: true

                    QMLTermWidget {
                        id: qmlTerm
                        anchors.fill: parent
                        anchors.margins: 4
                        font.family: "Monospace"
                        font.pointSize: 10

                        session: QMLTermSession {
                            id: termSession
                            shellProgram: "/usr/bin/tmux"
                            shellProgramArgs: ["-L", spikeRoot.tmuxSocket, "attach", "-t", spikeRoot.tmuxSession]
                            initialWorkingDirectory: "$HOME"

                            Component.onCompleted: {
                                termSession.startShellProgram();
                            }
                        }
                    }
                }

                // Candidate 2: Pure QML tmux capture-pane
                Rectangle {
                    color: "#0c0c0e"
                    radius: 8
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            TextEdit {
                                id: paneText
                                width: parent.width
                                readOnly: true
                                text: spikeRoot.candidate2Output
                                font.family: "Monospace"
                                font.pixelSize: 12
                                color: "#00ff66"
                                selectByMouse: true
                            }
                        }

                        // Input prompt simulator for Candidate 2
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            TextField {
                                id: candidate2Input
                                Layout.fillWidth: true
                                placeholderText: i18n("Type command and press Enter (mapped via tmux send-keys)...")
                                font.family: "Monospace"
                                font.pixelSize: 12
                                onAccepted: {
                                    if (text.length > 0) {
                                        execEngine.connectSource("tmux -L " + spikeRoot.tmuxSocket + " send-keys -t " + spikeRoot.tmuxSession + " \"" + text + "\" Enter");
                                        text = "";
                                        pollTimer.restart();
                                    }
                                }
                            }

                            Button {
                                text: i18n("Ctrl+C")
                                onClicked: spikeRoot.sendKeyToTmux("C-c")
                            }
                        }
                    }
                }
            }

            // Footer info
            Text {
                Layout.fillWidth: true
                text: spikeRoot.selectedCandidate === 0
                    ? i18n("Candidate 1 provides complete terminal emulation via Konsole's Qt6 engine. Tab, Ctrl+R, vi, sudo prompts, colors, and resize work out of the box.")
                    : i18n("Candidate 2 polls capture-pane every 150ms and routes inputs through send-keys. Causes high CPU, input latency, and lacks full TUI/cursor escape support.")
                font.family: "SF Hello"
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.45)
                wrapMode: Text.Wrap
            }
        }
    }
}
