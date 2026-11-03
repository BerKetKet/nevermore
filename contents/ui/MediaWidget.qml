import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

Rectangle {
    id: mediaRoot
    Layout.fillWidth: true
    implicitHeight: mediaCol.implicitHeight + 24
    radius: 14
    color: Qt.rgba(1, 1, 1, 0.04)
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    Mpris.Mpris2Model {
        id: mprisModel
    }

    property int playerCount: 0

    function updatePlayerCount() {
        playerCount = mprisModel.rowCount();
    }

    function nextPlayer() {
        if (playerCount <= 1) return;
        mprisModel.currentIndex = (mprisModel.currentIndex + 1) % playerCount;
    }

    function prevPlayer() {
        if (playerCount <= 1) return;
        mprisModel.currentIndex = (mprisModel.currentIndex - 1 + playerCount) % playerCount;
    }

    Connections {
        target: mprisModel
        function onRowsInserted() { mediaRoot.updatePlayerCount(); }
        function onRowsRemoved() { mediaRoot.updatePlayerCount(); }
        function onModelReset() { mediaRoot.updatePlayerCount(); }
        function onLayoutChanged() { mediaRoot.updatePlayerCount(); }
    }

    Component.onCompleted: updatePlayerCount()

    readonly property var player: mprisModel.currentPlayer
    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property string trackTitle: hasPlayer && player.track ? player.track : i18n("No Media Playing")
    readonly property string artistName: hasPlayer && player.artist ? player.artist : ""
    readonly property string albumName: hasPlayer && player.album ? player.album : ""
    readonly property url artUrl: hasPlayer && player.artUrl ? player.artUrl : ""
    readonly property bool isPlaying: hasPlayer && player.playbackStatus === Mpris.PlaybackStatus.Playing

    ColumnLayout {
        id: mediaCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Section Title & Multi-Player Switcher
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Kirigami.Icon {
                source: "multimedia-audio-player"
                implicitWidth: 16
                implicitHeight: 16
                color: "#ff2d55"
            }
            Text {
                text: i18n("Now Playing")
                font.family: "SF Hello"
                font.pixelSize: 13
                font.bold: true
                color: "#ffffff"
            }

            Item { Layout.fillWidth: true }

            // Multi-Player Switcher
            RowLayout {
                spacing: 4
                visible: mediaRoot.playerCount > 1

                // Prev Player Button
                Rectangle {
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 4
                    color: prevPlayerM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: prevPlayerM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaRoot.prevPlayer()
                    }
                }

                // Player Identity & Counter (e.g. "Spotify (1/2)")
                Text {
                    text: (mediaRoot.player && mediaRoot.player.identity ? mediaRoot.player.identity : i18n("Player")) +
                          " (" + (mprisModel.currentIndex + 1) + "/" + mediaRoot.playerCount + ")"
                    font.family: "SF Hello"
                    font.pixelSize: 10
                    font.bold: true
                    color: Qt.rgba(1, 1, 1, 0.7)
                }

                // Next Player Button
                Rectangle {
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 4
                    color: nextPlayerM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: nextPlayerM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaRoot.nextPlayer()
                    }
                }
            }
        }

        // Main Player Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Album Artwork / Placeholder
            Rectangle {
                implicitWidth: 54
                implicitHeight: 54
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.08)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                clip: true

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: mediaRoot.artUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "audio-x-generic"
                    implicitWidth: 26
                    implicitHeight: 26
                    color: Qt.rgba(1, 1, 1, 0.5)
                    visible: !mediaRoot.artUrl || albumArt.status !== Image.Ready
                }
            }

            // Track info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: mediaRoot.trackTitle
                    font.family: "SF Hello"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#ffffff"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: mediaRoot.artistName !== "" ? mediaRoot.artistName : (mediaRoot.hasPlayer ? i18n("Unknown Artist") : i18n("Ready for playback"))
                    font.family: "SF Hello"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.5)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Controls
            RowLayout {
                spacing: 4

                // Prev
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: prevM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "media-skip-backward"
                        implicitWidth: 14
                        implicitHeight: 14
                        color: mediaRoot.hasPlayer ? "#ffffff" : Qt.rgba(1, 1, 1, 0.3)
                    }
                    MouseArea {
                        id: prevM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: mediaRoot.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (mediaRoot.hasPlayer && mediaRoot.player.canGoPrevious) mediaRoot.player.Previous()
                    }
                }

                // Play / Pause
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: playM.containsMouse ? "#006ee6" : "#0a84ff"
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: mediaRoot.isPlaying ? "media-playback-pause" : "media-playback-start"
                        implicitWidth: 16
                        implicitHeight: 16
                        color: "#ffffff"
                    }
                    MouseArea {
                        id: playM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: mediaRoot.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (mediaRoot.hasPlayer) mediaRoot.player.PlayPause()
                    }
                }

                // Next
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: nextM.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "media-skip-forward"
                        implicitWidth: 14
                        implicitHeight: 14
                        color: mediaRoot.hasPlayer ? "#ffffff" : Qt.rgba(1, 1, 1, 0.3)
                    }
                    MouseArea {
                        id: nextM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: mediaRoot.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (mediaRoot.hasPlayer && mediaRoot.player.canGoNext) mediaRoot.player.Next()
                    }
                }
            }
        }
    }
}
