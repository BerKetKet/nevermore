import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume as Vol

Rectangle {
    id: volRoot
    Layout.fillWidth: true
    implicitHeight: volCol.implicitHeight + 24
    radius: 14
    color: Qt.rgba(1, 1, 1, 0.04)
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    property var sink: Vol.PreferredDevice.sink
    property var source: Vol.PreferredDevice.source

    readonly property bool hasSink: sink !== null && sink !== undefined
    readonly property bool hasSource: source !== null && source !== undefined

    readonly property int maxVol: Vol.PulseAudio.NormalVolume
    readonly property int outputPercent: hasSink && maxVol > 0 ? Math.round((sink.volume / maxVol) * 100) : 0
    readonly property int inputPercent: hasSource && maxVol > 0 ? Math.round((source.volume / maxVol) * 100) : 0

    ColumnLayout {
        id: volCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Section Title
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Icon {
                source: "audio-volume-high"
                implicitWidth: 18
                implicitHeight: 18
                color: "#30d158"
            }
            Text {
                text: i18n("Sound & Audio")
                font.family: "SF Hello"
                font.pixelSize: 14
                font.bold: true
                color: "#ffffff"
                Layout.fillWidth: true
            }
        }

        // --- Master Output Slider ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                // Mute icon button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    opacity: volRoot.hasSink ? 1.0 : 0.4
                    color: outMuteM.containsMouse && volRoot.hasSink ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: (volRoot.hasSink && volRoot.sink.muted) ? "audio-volume-muted" : "audio-volume-high"
                        implicitWidth: 14
                        implicitHeight: 14
                        color: (volRoot.hasSink && volRoot.sink.muted) ? "#ff453a" : "#ffffff"
                    }
                    MouseArea {
                        id: outMuteM
                        anchors.fill: parent
                        enabled: volRoot.hasSink
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (volRoot.hasSink) volRoot.sink.muted = !volRoot.sink.muted
                    }
                }

                Text {
                    text: i18n("Master Output")
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    font.bold: true
                    color: volRoot.hasSink ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: volRoot.hasSink ? (volRoot.sink.muted ? i18n("Muted") : volRoot.outputPercent + "%") : "—"
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    font.bold: true
                    color: !volRoot.hasSink ? Qt.rgba(1, 1, 1, 0.4) : (volRoot.sink.muted ? "#ff453a" : "#30d158")
                }
            }

            Slider {
                id: outSlider
                Layout.fillWidth: true
                enabled: volRoot.hasSink
                opacity: volRoot.hasSink ? 1.0 : 0.4
                from: 0
                to: 100
                value: volRoot.outputPercent
                onMoved: {
                    if (volRoot.hasSink) {
                        volRoot.sink.volume = Math.round((value / 100) * volRoot.maxVol);
                        if (volRoot.sink.muted) volRoot.sink.muted = false;
                    }
                }
            }
        }

        // --- Microphone Input Slider ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                // Mute mic button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    opacity: volRoot.hasSource ? 1.0 : 0.4
                    color: inMuteM.containsMouse && volRoot.hasSource ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: (volRoot.hasSource && volRoot.source.muted) ? "microphone-sensitivity-muted" : "microphone-sensitivity-high"
                        implicitWidth: 14
                        implicitHeight: 14
                        color: (volRoot.hasSource && volRoot.source.muted) ? "#ff453a" : "#ffffff"
                    }
                    MouseArea {
                        id: inMuteM
                        anchors.fill: parent
                        enabled: volRoot.hasSource
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (volRoot.hasSource) volRoot.source.muted = !volRoot.source.muted
                    }
                }

                Text {
                    text: i18n("Microphone")
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    font.bold: true
                    color: volRoot.hasSource ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: volRoot.hasSource ? (volRoot.source.muted ? i18n("Muted") : volRoot.inputPercent + "%") : "—"
                    font.family: "SF Hello"
                    font.pixelSize: 12
                    font.bold: true
                    color: !volRoot.hasSource ? Qt.rgba(1, 1, 1, 0.4) : (volRoot.source.muted ? "#ff453a" : "#0a84ff")
                }
            }

            Slider {
                id: inSlider
                Layout.fillWidth: true
                enabled: volRoot.hasSource
                opacity: volRoot.hasSource ? 1.0 : 0.4
                from: 0
                to: 100
                value: volRoot.inputPercent
                onMoved: {
                    if (volRoot.hasSource) {
                        volRoot.source.volume = Math.round((value / 100) * volRoot.maxVol);
                        if (volRoot.source.muted) volRoot.source.muted = false;
                    }
                }
            }
        }
    }
}
