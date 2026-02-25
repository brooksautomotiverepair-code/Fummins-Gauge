import QtQuick 2.15

Item {
    id: plate

    property int radius: 16
    property color borderColor: "#6a6a6a"
    property color topColor: "#2b2b2b"
    property color bottomColor: "#0f0f0f"
    property real borderWidth: 1

    Rectangle {
        anchors.fill: parent
        radius: plate.radius
        border.color: plate.borderColor
        border.width: plate.borderWidth

        gradient: Gradient {
            GradientStop { position: 0.0; color: plate.topColor }
            GradientStop { position: 1.0; color: plate.bottomColor }
        }
    }

    // inner edge
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(plate.radius - 2, 0)
        color: "transparent"
        border.width: 1
        border.color: "#3a3a3a"
        opacity: 0.65
    }

    // top shine
    Rectangle {
        x: 6
        y: 6
        width: parent.width - 12
        height: parent.height * 0.35
        radius: plate.radius
        color: "white"
        opacity: 0.06
    }
}
