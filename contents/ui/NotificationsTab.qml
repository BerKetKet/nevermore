import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NM
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: notifRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    signal actionInvoked()

    property var notifModel: null
    readonly property int notifCount: notifModel ? notifModel.count : 0
    readonly property bool isDnd: NM.Server.inhibited

    // Optional fallback: KWin script executor to raise application windows by desktopEntry
    Plasma5Support.DataSource {
        id: kwinActivator
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
        }
    }

    function raiseApp(desktopEntry, appName) {
        let target = (desktopEntry || appName || "").trim();
        if (!target) return;
        target = target.replace(/[^a-zA-Z0-9_\-\.]/g, "");
        if (!target) return;
        let pyScript = "import subprocess; js = '''let wins = workspace.windowList(); for (let w of wins) { let d = w.desktopFileName || ''; let r = w.resourceClass || ''; if (d.indexOf(\\\"" + target + "\\\") !== -1 || r.indexOf(\\\"" + target + "\\\") !== -1) { workspace.activeWindow = w; break; } }'''; f = open('/tmp/kwin_act.js', 'w'); f.write(js); f.close(); sid = subprocess.check_output(['qdbus6', 'org.kde.KWin', '/Scripting', 'org.kde.kwin.Scripting.loadScript', '/tmp/kwin_act.js']).decode().strip(); subprocess.run(['qdbus6', 'org.kde.KWin', f'/Scripting/Script{sid}', 'org.kde.kwin.Script.run']); subprocess.run(['qdbus6', 'org.kde.KWin', f'/Scripting/Script{sid}', 'org.kde.kwin.Script.stop']);";
        kwinActivator.connectSource("python3 -c \"" + pyScript + "\"");
        notifRoot.actionInvoked();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Top Control Bar: DND and Clear All
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // DND Toggle Button
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 10
                color: notifRoot.isDnd ? Qt.rgba(191/255, 90/255, 242/255, 0.25) : (dndMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
                border.color: notifRoot.isDnd ? "#bf5af2" : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Kirigami.Icon {
                        source: notifRoot.isDnd ? "notifications-disabled" : "notifications"
                        implicitWidth: 16
                        implicitHeight: 16
                        color: notifRoot.isDnd ? "#bf5af2" : "#ffffff"
                    }

                    Text {
                        text: notifRoot.isDnd ? i18n("Do Not Disturb: On") : i18n("Do Not Disturb")
                        font.family: "SF Hello"
                        font.pixelSize: 12
                        font.bold: true
                        color: notifRoot.isDnd ? "#bf5af2" : "#ffffff"
                    }
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NM.Server.inhibited = !NM.Server.inhibited
                }
            }

            // Clear All Button
            Rectangle {
                implicitWidth: clearText.implicitWidth + 24
                implicitHeight: 36
                radius: 10
                color: clearMouse.containsMouse ? Qt.rgba(1.0, 69/255, 58/255, 0.25) : Qt.rgba(1, 1, 1, 0.06)
                border.color: clearMouse.containsMouse ? "#ff453a" : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                visible: notifRoot.notifCount > 0

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Kirigami.Icon {
                        source: "edit-clear-all"
                        implicitWidth: 14
                        implicitHeight: 14
                        color: clearMouse.containsMouse ? "#ff453a" : Qt.rgba(1, 1, 1, 0.7)
                    }

                    Text {
                        id: clearText
                        text: i18n("Clear All")
                        font.family: "SF Hello"
                        font.pixelSize: 12
                        font.bold: true
                        color: clearMouse.containsMouse ? "#ff453a" : "#ffffff"
                    }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (notifModel) {
                            notifModel.clear(NM.Notifications.ClearExpired);
                        }
                    }
                }
            }
        }

        // Notification List or Empty State
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // --- Empty State ---
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                visible: notifRoot.notifCount === 0

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: 32
                    color: Qt.rgba(1, 1, 1, 0.05)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: notifRoot.isDnd ? "notifications-disabled" : "notifications"
                        implicitWidth: 32
                        implicitHeight: 32
                        color: Qt.rgba(1, 1, 1, 0.35)
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: notifRoot.isDnd ? i18n("Notifications Paused") : i18n("No Notifications")
                    font.family: "SF Hello"
                    font.pixelSize: 15
                    font.bold: true
                    color: "#ffffff"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: notifRoot.isDnd ? i18n("Do Not Disturb is currently active") : i18n("You're all caught up!")
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    color: Qt.rgba(1, 1, 1, 0.45)
                }
            }

            // --- Notifications ListView ---
            ListView {
                id: notifList
                anchors.fill: parent
                visible: notifRoot.notifCount > 0
                clip: true
                spacing: 10
                model: notifRoot.notifModel

                delegate: Rectangle {
                    id: notifItem
                    width: notifList.width
                    implicitHeight: notifCol.implicitHeight + 20
                    radius: 12
                    readonly property bool hasAction: model.hasDefaultAction === true
                    readonly property bool canRaiseApp: !hasAction && ((model.desktopEntry && model.desktopEntry !== "") || (model.applicationName && model.applicationName !== ""))
                    readonly property bool isInteractive: hasAction || canRaiseApp
                    color: (isInteractive && cardMouse.containsMouse) ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: (isInteractive && cardMouse.containsMouse) ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: notifItem.isInteractive
                        cursorShape: notifItem.isInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor
                        z: 0

                        onClicked: {
                            if (notifItem.hasAction && notifRoot.notifModel) {
                                notifRoot.notifModel.invokeDefaultAction(notifRoot.notifModel.index(index, 0), NM.Notifications.Close);
                                notifRoot.actionInvoked();
                            } else if (notifItem.canRaiseApp) {
                                notifRoot.raiseApp(model.desktopEntry, model.applicationName);
                            }
                        }
                    }

                    ColumnLayout {
                        id: notifCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6
                        z: 1

                        // Header: Icon, App Name, Time, Close
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Kirigami.Icon {
                                source: model.applicationIconName || model.iconName || "dialog-information"
                                implicitWidth: 18
                                implicitHeight: 18
                            }

                            Text {
                                text: model.applicationName || i18n("System")
                                font.family: "SF Hello"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#0a84ff"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Dismiss button
                            Rectangle {
                                z: 2
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: itemDismissM.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 11
                                    color: Qt.rgba(1, 1, 1, 0.6)
                                }

                                MouseArea {
                                    id: itemDismissM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        mouse.accepted = true;
                                        if (notifRoot.notifModel) {
                                            notifRoot.notifModel.close(notifRoot.notifModel.index(index, 0));
                                        }
                                    }
                                }
                            }
                        }

                        // Summary / Title
                        Text {
                            text: model.summary || ""
                            textFormat: Text.PlainText
                            font.family: "SF Hello"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#ffffff"
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            visible: text !== ""
                        }

                        // Body
                        Text {
                            text: model.body || ""
                            textFormat: Text.StyledText
                            font.family: "SF Hello"
                            font.pixelSize: 12
                            color: Qt.rgba(1, 1, 1, 0.7)
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }
                }
            }
        }
    }
}
