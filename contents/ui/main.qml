import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NM

PlasmoidItem {
    id: root

    // Single-surface architecture: Always render compact trigger in the panel,
    // and display the complete control center strictly within the zero-strut popup dialog.
    preferredRepresentation: compactRepresentation

    // Enable native toggle behavior on shortcut activation
    activationTogglesExpanded: true

    // Prevent immediate close on deactivation so toggle control center overlay stays open while active
    hideOnWindowDeactivate: false

    compactRepresentation: MouseArea {
        id: compactRoot
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitWidth: Kirigami.Units.gridUnit * 2
        implicitHeight: Kirigami.Units.gridUnit * 2
        hoverEnabled: true

        Timer {
            id: hoverExpandTimer
            interval: 150
            repeat: false
            onTriggered: {
                if (compactRoot.containsMouse && !root.expanded) {
                    root.expanded = true;
                }
            }
        }

        onEntered: hoverExpandTimer.restart()
        onExited: hoverExpandTimer.stop()
        onClicked: {
            hoverExpandTimer.stop();
            root.expanded = !root.expanded;
        }

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: compactRoot.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

            Kirigami.Icon {
                anchors.centerIn: parent
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                source: "sidebar-expand-right"
            }
        }
    }

    NM.Notifications {
        id: sharedNotifModel
        showExpired: true
        showDismissed: false
    }

    property int activeTab: 0 // 0: Widgets, 1: Notifications, 2: Run
    property string currentDateString: Qt.formatDate(new Date(), "dddd, MMMM d")

    function updateCurrentDate() {
        currentDateString = Qt.formatDate(new Date(), "dddd, MMMM d");
    }

    onVisibleChanged: {
        if (visible) updateCurrentDate();
    }

    Timer {
        id: dateRolloverTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.updateCurrentDate()
    }

    fullRepresentation: Rectangle {
        id: controlCenterPanel
        Layout.minimumWidth: 360
        Layout.preferredWidth: 380
        Layout.maximumWidth: 420
        Layout.minimumHeight: 600
        Layout.preferredHeight: Screen.desktopAvailableHeight > 100 ? Math.max(750, Screen.desktopAvailableHeight - 24) : 980
        Layout.maximumHeight: Screen.desktopAvailableHeight > 100 ? Screen.desktopAvailableHeight : 1050
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
                        text: root.currentDateString
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
                implicitHeight: 38
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
                                visible: sharedNotifModel.count > 0

                                Text {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: sharedNotifModel.count
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
                    notifModel: sharedNotifModel
                    visible: root.activeTab === 1
                    onActionInvoked: root.expanded = false
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
