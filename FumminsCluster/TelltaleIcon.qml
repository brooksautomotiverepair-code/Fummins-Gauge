import QtQuick 2.15

Item {
    id: root

    property url source: ""
    property int size: 44

    property bool on: false
    property bool blink: false

    // Day/Night dimming
    property bool nightMode: false
    property real dayBrightness: 1.0
    property real nightBrightness: 0.55

    // NEW: bulb-check fade multiplier (0..1)
    property real testBrightness: 1.0

    // Internal: blink opacity
    property real blinkOpacity: 1.0

    width: size
    height: size
    visible: on

    // Final brightness stack:
    // blinkOpacity * day/night brightness * testBrightness
    opacity: on
             ? (blinkOpacity
                * (nightMode ? nightBrightness : dayBrightness)
                * testBrightness)
             : 0.0

    Image {
        anchors.fill: parent
        source: root.source
        smooth: true
    }

    SequentialAnimation {
        id: blinkAnim
        running: root.on && root.blink
        loops: Animation.Infinite

        NumberAnimation { target: root; property: "blinkOpacity"; to: 0.25; duration: 260 }
        NumberAnimation { target: root; property: "blinkOpacity"; to: 1.0;  duration: 260 }

        onStopped: root.blinkOpacity = 1.0
    }

    onOnChanged: {
        if (!on) blinkOpacity = 1.0
    }

    onBlinkChanged: {
        if (!blink) blinkOpacity = 1.0
    }
}
