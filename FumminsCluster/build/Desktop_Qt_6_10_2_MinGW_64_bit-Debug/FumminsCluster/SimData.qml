import QtQuick 2.15

Item {
    id: root

    // This item doesn't need to be visible
    width: 0
    height: 0
    visible: false

    // Allows Main.qml to disable the sim during boot
    property bool enabled: true

    property int rpm: 800
    property int speed: 0
    property int coolant: 160
    property bool leftTurn: false
    property bool rightTurn: false
    property bool highBeam: false

    property int phase: 0

    Timer {
        interval: 33
        running: root.enabled
        repeat: true
        onTriggered: {
            root.phase += 1

            root.rpm = 800 + (root.phase % 2400)
            root.speed = Math.max(0, (root.rpm - 800) / 60)
            root.coolant = 160 + ((root.phase / 90) % 60)

            root.leftTurn  = ((root.phase / 12) % 2) === 0
            root.rightTurn = ((root.phase / 16) % 2) === 0
            root.highBeam  = ((root.phase / 40) % 2) === 0
        }
    }
}
