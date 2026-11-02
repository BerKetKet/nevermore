import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NM

Item {
    id: notifRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    NM.Notifications {
        id: notifModel
        showExpired: true
        showDismissed: false
    }

    readonly property bool isDnd: NM.Server.inhibited

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
                height: 36
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
                height: 36
                radius: 10
                color: clearMouse.containsMouse ? Qt.rgba(1.0, 69/255, 58/255, 0.25) : Qt.rgba(1, 1, 1, 0.06)
                border.color: clearMouse.containsMouse ? "#ff453a" : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                visible: notifModel.count > 0

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
                    onClicked: notifModel.clear(0xFFFF)
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
                visible: notifModel.count === 0

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
                visible: notifModel.count > 0
                clip: true
                spacing: 10
                model: notifModel

                delegate: Rectangle {
                    id: notifItem
                    width: notifList.width
                    implicitHeight: notifCol.implicitHeight + 20
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: notifCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

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
                                    onClicked: notifModel.close(notifModel.index(index, 0))
                                }
                            }
                        }

                        // Summary / Title
                        Text {
                            text: model.summary || ""
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
