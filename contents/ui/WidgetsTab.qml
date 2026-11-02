import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: scrollRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: availableWidth
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
        width: scrollRoot.availableWidth
        spacing: 12

        // 1. Calendar
        CalendarWidget {
            Layout.fillWidth: true
        }

        // 2. Hardware Monitor (CPU, RAM, Disk, Network)
        HardwareWidget {
            Layout.fillWidth: true
        }

        // 3. Media Player (MPRIS)
        MediaWidget {
            Layout.fillWidth: true
        }

        // 4. Volume / Sound Controls
        VolumeWidget {
            Layout.fillWidth: true
        }

        Item {
            implicitHeight: 16
        }
    }
}
