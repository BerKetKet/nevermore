import QtQuick
import QMLTermWidget 2.0

Item {
    id: termView
    anchors.fill: parent
    focus: true

    property string confPath: ""
    property string userHome: ""
    property string tmuxSocket: "nevermore"
    property string tmuxSession: "term"

    function forceTerminalFocus() {
        qmlTerm.forceActiveFocus();
    }

    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            qmlTerm.forceActiveFocus();
        }
    }

    QMLTermWidget {
        id: qmlTerm
        anchors.fill: parent
        anchors.margins: 4
        font.family: "Noto Sans Mono"
        font.pointSize: 10
        focus: true

        session: QMLTermSession {
            id: termSession
            shellProgram: "/usr/bin/tmux"
            shellProgramArgs: [
                "-L", termView.tmuxSocket,
                "-f", termView.confPath,
                "new-session", "-A", "-s", termView.tmuxSession
            ]
            initialWorkingDirectory: termView.userHome

            Component.onCompleted: {
                termSession.startShellProgram();
                qmlTerm.forceActiveFocus();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: qmlTerm.forceActiveFocus()
    }
}
