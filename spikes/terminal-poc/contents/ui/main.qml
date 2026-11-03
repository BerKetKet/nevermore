import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: spikeRoot

    Plasmoid.status: PlasmaCore.Types.AcceptingInputStatus
    preferredRepresentation: fullRepresentation
    width: 600
    height: 700
    focus: true

    property string tmuxSocket: "nevermore"
    property string tmuxSession: "term"
    property string confPath: Qt.resolvedUrl("../../nevermore-tmux.conf").toString().replace(/^file:\/\//, "")
    property string userHome: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "")
    property int selectedCandidate: 0 // 0: QMLTermWidget (Qt6), 1: Pure QML (capture-pane)
    property string candidate2Output: ""
    property var termWidgetLoader: null

    onVisibleChanged: {
        if (visible && termWidgetLoader && termWidgetLoader.item && typeof termWidgetLoader.item.forceTerminalFocus === "function") {
            termWidgetLoader.item.forceTerminalFocus();
        }
    }

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
        execEngine.connectSource("konsole -e tmux -L " + spikeRoot.tmuxSocket + " -f \"" + spikeRoot.confPath + "\" new-session -A -s " + spikeRoot.tmuxSession);
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
        focus: true

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
                    text: i18n("Candidate 1: QMLTermWidget")
                    highlighted: spikeRoot.selectedCandidate === 0
                    onClicked: {
                        spikeRoot.selectedCandidate = 0;
                        if (termLoader.item && typeof termLoader.item.forceTerminalFocus === "function") {
                            termLoader.item.forceTerminalFocus();
                        }
                    }
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

                // Candidate 1 Viewport with Loader
                Rectangle {
                    color: "#0c0c0e"
                    radius: 8
                    clip: true

                    Loader {
                        id: termLoader
                        anchors.fill: parent
                        focus: true
                        Component.onCompleted: {
                            spikeRoot.termWidgetLoader = termLoader;
                            termLoader.setSource("TermWidgetView.qml", {
                                "confPath": spikeRoot.confPath,
                                "userHome": spikeRoot.userHome,
                                "tmuxSocket": spikeRoot.tmuxSocket,
                                "tmuxSession": spikeRoot.tmuxSession
                            });
                        }
                    }

                    // Fallback UI when QMLTermWidget module is not installed
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        visible: termLoader.status === Loader.Error
                        width: parent.width - 40

                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignHCenter
                            source: "dialog-warning"
                            implicitWidth: 32
                            implicitHeight: 32
                            color: "#ff9f0a"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: i18n("qmltermwidget Qt6 Module Not Found")
                            font.family: "SF Hello"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#ffffff"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: i18n("The QMLTermWidget native module is not installed on this system. Install package 'qmltermwidget' from your distribution repositories (e.g. pacman -S qmltermwidget), or launch your session in external Konsole below.")
                            font.family: "SF Hello"
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.6)
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Button {
                            Layout.alignment: Qt.AlignHCenter
                            text: i18n("Open in Konsole")
                            icon.name: "konsole"
                            onClicked: spikeRoot.openInKonsole()
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            if (termLoader.item && typeof termLoader.item.forceTerminalFocus === "function") {
                                termLoader.item.forceTerminalFocus();
                            }
                        }
                    }
                }

                // Candidate 2 Viewport (Pure QML capture-pane)
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
                                placeholderText: i18n("Type command and press Enter (tmux send-keys)...")
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
                    ? i18n("Candidate 1 embeds Konsole's Qt6 terminal engine directly in QML, attached to tmux on socket 'nevermore'.")
                    : i18n("Candidate 2 polls capture-pane and routes inputs via send-keys.")
                font.family: "SF Hello"
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.45)
                wrapMode: Text.Wrap
            }
        }
    }
}
