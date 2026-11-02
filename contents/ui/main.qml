import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NM

PlasmoidItem {
    id: root

    // Force full rich representation
    preferredRepresentation: fullRepresentation

    NM.Notifications {
        id: notifCounter
        showExpired: true
        showDismissed: false
    }

    property int activeTab: 0 // 0: Widgets, 1: Notifications, 2: Terminal

    fullRepresentation: Rectangle {
        id: controlCenterPanel
        Layout.minimumWidth: 360
        Layout.preferredWidth: 380
        Layout.maximumWidth: 420
        Layout.fillHeight: true

        color: "#18181b"
        radius: 16
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            // --- Top Header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Kirigami.Icon {
                    source: "sidebar-expand-right"
                    implicitWidth: 20
                    implicitHeight: 20
                    color: "#0a84ff"
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: i18n("Control Center")
                        font.family: "SF Hello"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#ffffff"
                    }
                    Text {
                        text: Qt.formatDate(new Date(), "dddd, MMMM d")
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // --- Dual Segmented Tabs (Widgets vs Notifications) ---
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.06)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    // Tab 1: Widgets
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: root.activeTab === 0 ? Qt.rgba(1, 1, 1, 0.16) : (tab0Mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Kirigami.Icon {
                                source: "view-list-icons"
                                implicitWidth: 15
                                implicitHeight: 15
                                color: root.activeTab === 0 ? "#0a84ff" : Qt.rgba(1, 1, 1, 0.6)
                            }

                            Text {
                                text: i18n("Widgets")
                                font.family: "SF Hello"
                                font.pixelSize: 12
                                font.bold: root.activeTab === 0
                                color: root.activeTab === 0 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                            }
                        }

                        MouseArea {
                            id: tab0Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 0
                        }
                    }

                    // Tab 2: Notifications
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: root.activeTab === 1 ? Qt.rgba(1, 1, 1, 0.16) : (tab1Mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Kirigami.Icon {
                                source: "notifications"
                                implicitWidth: 15
                                implicitHeight: 15
                                color: root.activeTab === 1 ? "#0a84ff" : Qt.rgba(1, 1, 1, 0.6)
                            }

                            Text {
                                text: i18n("Notifications")
                                font.family: "SF Hello"
                                font.pixelSize: 12
                                font.bold: root.activeTab === 1
                                color: root.activeTab === 1 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                            }

                            // Unread Badge
                            Rectangle {
                                implicitWidth: Math.max(16, badgeText.implicitWidth + 8)
                                implicitHeight: 16
                                radius: 8
                                color: "#ff453a"
                                visible: notifCounter.count > 0

                                Text {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: notifCounter.count
                                    font.family: "SF Hello"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#ffffff"
                                }
                            }
                        }

                        MouseArea {
                            id: tab1Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 1
                        }
                    }

                    // Tab 3: Terminal
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: root.activeTab === 2 ? Qt.rgba(1, 1, 1, 0.16) : (tab2Mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Kirigami.Icon {
                                source: "utilities-terminal"
                                implicitWidth: 15
                                implicitHeight: 15
                                color: root.activeTab === 2 ? "#0a84ff" : Qt.rgba(1, 1, 1, 0.6)
                            }

                            Text {
                                text: i18n("Terminal")
                                font.family: "SF Hello"
                                font.pixelSize: 12
                                font.bold: root.activeTab === 2
                                color: root.activeTab === 2 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                            }
                        }

                        MouseArea {
                            id: tab2Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 2
                        }
                    }
                }
            }

            // --- Tab Content View ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Widgets View
                WidgetsTab {
                    anchors.fill: parent
                    visible: root.activeTab === 0
                }

                // Notifications View
                NotificationsTab {
                    anchors.fill: parent
                    visible: root.activeTab === 1
                }

                // Terminal View
                TerminalTab {
                    anchors.fill: parent
                    visible: root.activeTab === 2
                }
            }
        }
    }
}
