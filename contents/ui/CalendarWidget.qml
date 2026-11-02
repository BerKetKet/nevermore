import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: calRoot
    Layout.fillWidth: true
    implicitHeight: calCol.implicitHeight + 24
    radius: 14
    color: Qt.rgba(1, 1, 1, 0.04)
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    property var today: new Date()
    property int displayedYear: today.getFullYear()
    property int displayedMonth: today.getMonth() // 0 - 11
    property int selectedDay: today.getDate()

    readonly property var monthNames: [
        i18n("January"), i18n("February"), i18n("March"), i18n("April"),
        i18n("May"), i18n("June"), i18n("July"), i18n("August"),
        i18n("September"), i18n("October"), i18n("November"), i18n("December")
    ]
    readonly property var weekDayNames: [
        i18n("Mo"), i18n("Tu"), i18n("We"), i18n("Th"), i18n("Fr"), i18n("Sa"), i18n("Su")
    ]

    property var daysModel: []

    function refreshDays() {
        let firstDayIndex = (new Date(displayedYear, displayedMonth, 1).getDay() + 6) % 7;
        let daysInCurrent = new Date(displayedYear, displayedMonth + 1, 0).getDate();
        let daysInPrev = new Date(displayedYear, displayedMonth, 0).getDate();
        let list = [];
        let t = new Date();

        // Previous month days
        for (let i = firstDayIndex - 1; i >= 0; i--) {
            list.push({
                day: daysInPrev - i,
                isCurrent: false,
                isToday: false
            });
        }
        // Current month days
        for (let i = 1; i <= daysInCurrent; i++) {
            let isT = (t.getFullYear() === displayedYear && t.getMonth() === displayedMonth && t.getDate() === i);
            list.push({
                day: i,
                isCurrent: true,
                isToday: isT
            });
        }
        // Next month days
        let remaining = 42 - list.length;
        for (let i = 1; i <= remaining; i++) {
            list.push({
                day: i,
                isCurrent: false,
                isToday: false
            });
        }
        daysModel = list;
    }

    Component.onCompleted: refreshDays()

    function prevMonth() {
        if (displayedMonth === 0) {
            displayedMonth = 11;
            displayedYear--;
        } else {
            displayedMonth--;
        }
        refreshDays();
    }

    function nextMonth() {
        if (displayedMonth === 11) {
            displayedMonth = 0;
            displayedYear++;
        } else {
            displayedMonth++;
        }
        refreshDays();
    }

    function goToday() {
        let t = new Date();
        displayedYear = t.getFullYear();
        displayedMonth = t.getMonth();
        selectedDay = t.getDate();
        refreshDays();
    }

    ColumnLayout {
        id: calCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Month & Navigation Header
        RowLayout {
            Layout.fillWidth: true

            Kirigami.Icon {
                source: "office-calendar"
                implicitWidth: 18
                implicitHeight: 18
                color: "#0a84ff"
            }

            Text {
                text: monthNames[displayedMonth] + " " + displayedYear
                font.family: "SF Hello"
                font.pixelSize: 14
                font.bold: true
                color: "#ffffff"
                Layout.fillWidth: true
            }

            // Today button
            Rectangle {
                implicitWidth: todayText.implicitWidth + 14
                implicitHeight: 24
                radius: 12
                color: todayMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                border.color: Qt.rgba(1, 1, 1, 0.1)

                Text {
                    id: todayText
                    anchors.centerIn: parent
                    text: i18n("Today")
                    font.family: "SF Hello"
                    font.pixelSize: 11
                    color: "#0a84ff"
                    font.bold: true
                }
                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calRoot.goToday()
                }
            }

            // Prev Button
            Rectangle {
                implicitWidth: 24
                implicitHeight: 24
                radius: 12
                color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ffffff"
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calRoot.prevMonth()
                }
            }

            // Next Button
            Rectangle {
                implicitWidth: 24
                implicitHeight: 24
                radius: 12
                color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ffffff"
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calRoot.nextMonth()
                }
            }
        }

        // Days of week header
        Row {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: calRoot.weekDayNames
                Item {
                    width: calCol.width / 7
                    height: 20
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: "SF Hello"
                        font.pixelSize: 11
                        font.bold: true
                        color: Qt.rgba(1, 1, 1, 0.45)
                    }
                }
            }
        }

        // Calendar Grid (42 cells: 7 columns x 6 rows)
        Grid {
            id: daysGrid
            Layout.fillWidth: true
            columns: 7
            rows: 6
            spacing: 0

            Repeater {
                model: calRoot.daysModel

                Item {
                    width: calCol.width / 7
                    height: 28

                    readonly property bool isCurrent: modelData.isCurrent
                    readonly property bool isToday: modelData.isToday
                    readonly property bool isSelected: isCurrent && modelData.day === calRoot.selectedDay

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: isToday ? "#0a84ff" : (isSelected ? Qt.rgba(10/255, 132/255, 1.0, 0.25) : (cellMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"))
                        border.color: isSelected && !isToday ? "#0a84ff" : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            font.family: "SF Hello"
                            font.pixelSize: 12
                            font.bold: isToday || isSelected
                            color: isToday ? "#ffffff" : (isCurrent ? "#e0e0e0" : Qt.rgba(1, 1, 1, 0.25))
                        }
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: isCurrent ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (isCurrent) {
                                calRoot.selectedDay = modelData.day;
                            }
                        }
                    }
                }
            }
        }
    }
}
