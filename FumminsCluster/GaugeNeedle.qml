import QtQuick 2.15

Item {
    id: root

    property real value: 0
    property real minValue: 0
    property real maxValue: 5000
    property real minAngle: -120
    property real maxAngle: 120

    property url source: ""
    property real pivotX: 0        // SOURCE IMAGE PIXELS
    property real pivotY: 0        // SOURCE IMAGE PIXELS
    property real needleScale: 1.0
    property int smoothMs: 120

    // ✅ NEW: lets Main/RoundGauge disable smoothing during sweep/settle
    property bool smoothEnabled: true

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
    function valueToAngle(v) {
        var denom = (maxValue - minValue)
        if (denom === 0) return minAngle
        var t = (clamp(v, minValue, maxValue) - minValue) / denom
        return minAngle + t * (maxAngle - minAngle)
    }

    // rotate container at center (prevents orbit)
    Item {
        id: needleRoot
        x: root.width / 2
        y: root.height / 2
        width: 0
        height: 0
        transformOrigin: Item.TopLeft

        rotation: root.valueToAngle(root.value)

        Behavior on rotation {
            enabled: root.smoothEnabled
            NumberAnimation { duration: root.smoothMs; easing.type: Easing.InOutQuad }
        }

        Image {
            id: needleImg
            source: root.source
            smooth: true

            scale: root.needleScale
            transformOrigin: Item.TopLeft

            // pivot lands on container origin (0,0)
            x: -root.pivotX * scale
            y: -root.pivotY * scale
        }
    }

    // Debug center (comment out when done)
    // Rectangle { width: 6; height: 6; radius: 3; color: "yellow"; x: root.width/2-3; y: root.height/2-3 }
}
