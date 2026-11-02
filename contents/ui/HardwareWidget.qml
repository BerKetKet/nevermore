import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

Rectangle {
    id: hwRoot
    Layout.fillWidth: true
    implicitHeight: hwCol.implicitHeight + 24
    radius: 14
    color: Qt.rgba(1, 1, 1, 0.04)
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    property double cpuUsage: 0
    property double memPercent: 0
    property double memUsed: 0
    property double memTotal: 0
    property double diskPercent: 0
    property double diskTotal: 0
    property double diskFree: 0
    property double netDown: 0
    property double netUp: 0

    Sensors.SensorDataModel {
        id: sensorModel
        enabled: hwRoot.visible
        sensors: [
            "cpu/all/usage",
            "memory/physical/usedPercent",
            "memory/physical/total",
            "memory/physical/used",
            "disk/all/usedPercent",
            "disk/all/total",
            "disk/all/free",
            "network/all/download",
            "network/all/upload"
        ]

        onDataChanged: hwRoot.updateMetrics()
    }

    function formatBytes(bytes) {
        if (!bytes || isNaN(bytes)) return "0 GB";
        let gb = bytes / (1024 * 1024 * 1024);
        return gb.toFixed(1) + " GB";
    }

    function formatSpeed(bytesPerSec) {
        if (!bytesPerSec || isNaN(bytesPerSec) || bytesPerSec <= 0) return "0 KB/s";
        let mb = bytesPerSec / (1024 * 1024);
        if (mb >= 1) return mb.toFixed(1) + " MB/s";
        let kb = bytesPerSec / 1024;
        return kb.toFixed(0) + " KB/s";
    }

    function updateMetrics() {
        if (!hwRoot.visible) return;

        let cpu = sensorModel.data(sensorModel.index(0, 0), Sensors.SensorDataModel.Value);
        if (cpu !== undefined && !isNaN(cpu)) cpuUsage = Math.max(0, Math.min(100, cpu));

        let memP = sensorModel.data(sensorModel.index(0, 1), Sensors.SensorDataModel.Value);
        if (memP !== undefined && !isNaN(memP)) memPercent = Math.max(0, Math.min(100, memP));

        let memT = sensorModel.data(sensorModel.index(0, 2), Sensors.SensorDataModel.Value);
        if (memT !== undefined && !isNaN(memT)) memTotal = memT;

        let memU = sensorModel.data(sensorModel.index(0, 3), Sensors.SensorDataModel.Value);
        if (memU !== undefined && !isNaN(memU)) memUsed = memU;

        let diskP = sensorModel.data(sensorModel.index(0, 4), Sensors.SensorDataModel.Value);
        if (diskP !== undefined && !isNaN(diskP)) diskPercent = Math.max(0, Math.min(100, diskP));

        let diskT = sensorModel.data(sensorModel.index(0, 5), Sensors.SensorDataModel.Value);
        if (diskT !== undefined && !isNaN(diskT)) diskTotal = diskT;

        let diskF = sensorModel.data(sensorModel.index(0, 6), Sensors.SensorDataModel.Value);
        if (diskF !== undefined && !isNaN(diskF)) diskFree = diskF;

        let nd = sensorModel.data(sensorModel.index(0, 7), Sensors.SensorDataModel.Value);
        if (nd !== undefined && !isNaN(nd)) netDown = nd;

        let nu = sensorModel.data(sensorModel.index(0, 8), Sensors.SensorDataModel.Value);
        if (nu !== undefined && !isNaN(nu)) netUp = nu;
    }

    onVisibleChanged: {
        if (visible) {
            updateMetrics();
        }
    }

    Component.onCompleted: updateMetrics()

    ColumnLayout {
        id: hwCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Section Title
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Icon {
                source: "speedometer"
                implicitWidth: 18
                implicitHeight: 18
                color: "#ff9f0a"
            }
            Text {
                text: i18n("Hardware Monitor")
                font.family: "SF Hello"
                font.pixelSize: 14
                font.bold: true
                color: "#ffffff"
                Layout.fillWidth: true
            }
        }

        // --- CPU Gauge ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Kirigami.Icon {
                    source: "cpu"
                    implicitWidth: 14
                    implicitHeight: 14
                    color: Qt.rgba(1, 1, 1, 0.7)
                }
                Text {
                    text: i18n("CPU Load")
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#ffffff"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(hwRoot.cpuUsage) + "%"
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#0a84ff"
                }
            }

            // CPU Bar
            Rectangle {
                Layout.fillWidth: true
                height: 7
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    height: parent.height
                    width: Math.max(7, parent.width * (hwRoot.cpuUsage / 100))
                    radius: 4
                    color: hwRoot.cpuUsage > 85 ? "#ff453a" : "#0a84ff"
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
        }

        // --- Memory (RAM) Gauge ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Kirigami.Icon {
                    source: "memory"
                    implicitWidth: 14
                    implicitHeight: 14
                    color: Qt.rgba(1, 1, 1, 0.7)
                }
                Text {
                    text: i18n("Memory (RAM)")
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#ffffff"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: hwRoot.formatBytes(hwRoot.memUsed) + " / " + hwRoot.formatBytes(hwRoot.memTotal) + " (" + Math.round(hwRoot.memPercent) + "%)"
                    font.family: "SF Hello"
                    font.pixelSize: 11
                    color: "#bf5af2"
                    font.bold: true
                }
            }

            // RAM Bar
            Rectangle {
                Layout.fillWidth: true
                height: 7
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    height: parent.height
                    width: Math.max(7, parent.width * (hwRoot.memPercent / 100))
                    radius: 4
                    color: hwRoot.memPercent > 90 ? "#ff453a" : "#bf5af2"
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
        }

        // --- Storage (Disk) Gauge ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Kirigami.Icon {
                    source: "drive-harddisk"
                    implicitWidth: 14
                    implicitHeight: 14
                    color: Qt.rgba(1, 1, 1, 0.7)
                }
                Text {
                    text: i18n("Storage (All Disks)")
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#ffffff"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: hwRoot.formatBytes(hwRoot.diskFree) + " free (" + Math.round(hwRoot.diskPercent) + "% used)"
                    font.family: "SF Hello"
                    font.pixelSize: 11
                    color: "#30d158"
                    font.bold: true
                }
            }

            // Disk Bar
            Rectangle {
                Layout.fillWidth: true
                height: 7
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    height: parent.height
                    width: Math.max(7, parent.width * (hwRoot.diskPercent / 100))
                    radius: 4
                    color: hwRoot.diskPercent > 90 ? "#ff9f0a" : "#30d158"
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
        }

        // --- Network Activity ---
        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.05)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // Download
                Kirigami.Icon {
                    source: "network-receive"
                    implicitWidth: 14
                    implicitHeight: 14
                    color: "#0a84ff"
                }
                Text {
                    text: hwRoot.formatSpeed(hwRoot.netDown)
                    font.family: "SF Hello"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#ffffff"
                }

                Item { Layout.fillWidth: true }

                // Upload
                Kirigami.Icon {
                    source: "network-transmit"
                    implicitWidth: 14
                    implicitHeight: 14
                    color: "#30d158"
                }
                Text {
                    text: hwRoot.formatSpeed(hwRoot.netUp)
                    font.family: "SF Hello"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#ffffff"
                }
            }
        }
    }
}
