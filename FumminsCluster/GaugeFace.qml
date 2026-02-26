import QtQuick 2.15

Item {
    id: root

    // IMPORTANT: let the parent control size (RoundGauge already does)
    // Do NOT hardcode width/height here.
    // width/height will come from anchors.fill in RoundGauge.

    // Geometry
    property real radius: Math.min(width, height) * 0.48
    property real centerX: width / 2
    property real centerY: height / 2

    // Dial config
    property real minValue: 0
    property real maxValue: 4000
    property int majorTicks: 9
    property int minorTicksPerMajor: 4
    property real startAngle: -120
    property real endAngle: 120

    // Tick mods
    property bool useValueTicks: false

    // Labeling
    property string units: "RPM"
    property bool showNumbers: true
    property real numberEvery: 500

    // Formatting
    property bool thousandsLabels: true
    property bool hideZeroLabel: true

    // Redline
    property real redlineFrom: 3200
    property real redlineTo: 4000
    property bool showRedline: true

    // Styling
    property color tickColor: "white"
    property color minorTickColor: "#bdbdbd"
    property color numberColor: "white"
    property color redlineColor: "#c21d1d"

    // Value-based tick styling
    property real tickStep: 1
    property real mediumTickLen: radius * 0.12
    property real mediumTickWidth: 3

    // Texture
    property url baseTexture: ""

    // Tuning knobs
    property real majorTickLen: radius * 0.16
    property real minorTickLen: radius * 0.09
    property real majorTickWidth: 4
    property real minorTickWidth: 2
    property real numberRadius: radius * 0.70
    property real redlineRadius: radius * 0.93
    property real redlineWidth: 6

    // Rings
    property bool showRings: true
    property color outerRingColor: "#2a2a2a"
    property color innerRingColor: "#111111"

    function lerp(a, b, t) { return a + (b - a) * t }
    function deg2rad(d) { return d * Math.PI / 180.0 }
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    function valueToAngle(v) {
        var t = (clamp(v, minValue, maxValue) - minValue) / (maxValue - minValue)
        return lerp(startAngle, endAngle, t)
    }

    function formatLabel(v) {
        if (hideZeroLabel && Math.round(v) === 0) return ""
        if (thousandsLabels) {
            // Only compress true thousands (1000,2000,3000...)
            if (Math.round(v) % 1000 === 0 && v >= 1000) return (v / 1000).toFixed(0)
        }
        return v.toFixed(0)
    }

    // Helper to repaint when any dial-relevant property changes
    function repaint() { dial.requestPaint() }

    onMinValueChanged: repaint()
    onMaxValueChanged: repaint()
    onMajorTicksChanged: repaint()
    onMinorTicksPerMajorChanged: repaint()
    onStartAngleChanged: repaint()
    onEndAngleChanged: repaint()
    onUseValueTicksChanged: repaint()
    onTickStepChanged: repaint()
    onTickColorChanged: repaint()
    onMinorTickColorChanged: repaint()
    onShowRedlineChanged: repaint()
    onRedlineFromChanged: repaint()
    onRedlineToChanged: repaint()
    onRedlineColorChanged: repaint()
    onShowRingsChanged: repaint()
    onOuterRingColorChanged: repaint()
    onInnerRingColorChanged: repaint()
    onMajorTickLenChanged: repaint()
    onMinorTickLenChanged: repaint()
    onMediumTickLenChanged: repaint()
    onMajorTickWidthChanged: repaint()
    onMinorTickWidthChanged: repaint()
    onMediumTickWidthChanged: repaint()
    onRedlineRadiusChanged: repaint()
    onRedlineWidthChanged: repaint()

    Image {
        anchors.fill: parent
        source: root.baseTexture
        visible: root.baseTexture !== ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Canvas {
        id: dial
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            if (root.showRings) {
                ctx.beginPath()
                ctx.strokeStyle = root.outerRingColor
                ctx.lineWidth = 10
                ctx.arc(root.centerX, root.centerY, root.radius * 1.00, 0, Math.PI * 2, false)
                ctx.stroke()

                ctx.beginPath()
                ctx.strokeStyle = root.innerRingColor
                ctx.lineWidth = 8
                ctx.arc(root.centerX, root.centerY, root.radius * 0.86, 0, Math.PI * 2, false)
                ctx.stroke()
            }

            function drawTick(angleDeg, len, thick, color) {
                var a = root.deg2rad(angleDeg)
                var rOuter = root.radius
                var rInner = root.radius - len

                var x1 = root.centerX + Math.cos(a) * rOuter
                var y1 = root.centerY + Math.sin(a) * rOuter
                var x2 = root.centerX + Math.cos(a) * rInner
                var y2 = root.centerY + Math.sin(a) * rInner

                ctx.beginPath()
                ctx.strokeStyle = color
                ctx.lineWidth = thick
                ctx.lineCap = "round"
                ctx.moveTo(x1, y1)
                ctx.lineTo(x2, y2)
                ctx.stroke()
            }

            if (root.useValueTicks) {
                // value-based ticks: big 10s, medium 5s, small others
                for (var v = root.minValue; v <= root.maxValue + 0.0001; v += root.tickStep) {
                    var vv = Math.round(v) // stabilize modulo
                    var ang = root.valueToAngle(v)

                    var len = root.minorTickLen
                    var thick = root.minorTickWidth
                    var col = root.minorTickColor

                    if (vv % 5 === 0) {
                        len = root.mediumTickLen
                        thick = root.mediumTickWidth
                        col = root.tickColor
                    }
                    if (vv % 10 === 0) {
                        len = root.majorTickLen
                        thick = root.majorTickWidth
                        col = root.tickColor
                    }

                    drawTick(ang, len, thick, col)
                }
            } else {
                var majors = root.majorTicks
                for (var i = 0; i < majors; i++) {
                    var tMajor = i / (majors - 1)
                    var angMajor = root.lerp(root.startAngle, root.endAngle, tMajor)
                    drawTick(angMajor, root.majorTickLen, root.majorTickWidth, root.tickColor)

                    if (i < majors - 1) {
                        for (var m = 1; m <= root.minorTicksPerMajor; m++) {
                            var tMinor = (i + m / (root.minorTicksPerMajor + 1)) / (majors - 1)
                            var angMinor = root.lerp(root.startAngle, root.endAngle, tMinor)
                            drawTick(angMinor, root.minorTickLen, root.minorTickWidth, root.minorTickColor)
                        }
                    }
                }
            }

            if (root.showRedline) {
                var a1 = root.deg2rad(root.valueToAngle(root.redlineFrom))
                var a2 = root.deg2rad(root.valueToAngle(root.redlineTo))

                ctx.beginPath()
                ctx.strokeStyle = root.redlineColor
                ctx.lineWidth = root.redlineWidth
                ctx.lineCap = "butt"
                ctx.arc(root.centerX, root.centerY, root.redlineRadius, a1, a2, false)
                ctx.stroke()
            }
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // Numbers (stable positioning using implicit sizes)
    Repeater {
        model: root.showNumbers ? Math.floor((root.maxValue - root.minValue) / root.numberEvery) + 1 : 0
        delegate: Text {
            property real v: root.minValue + index * root.numberEvery
            property real a: root.deg2rad(root.valueToAngle(v))

            text: root.formatLabel(v)
            visible: text !== ""
            color: root.numberColor
            font.pixelSize: root.width * 0.070
            font.bold: true

            x: root.centerX + Math.cos(a) * root.numberRadius - implicitWidth / 2
            y: root.centerY + Math.sin(a) * root.numberRadius - implicitHeight / 2

            // force re-eval when font/implicit size updates
            onImplicitWidthChanged:  { x = root.centerX + Math.cos(a) * root.numberRadius - implicitWidth / 2 }
            onImplicitHeightChanged: { y = root.centerY + Math.sin(a) * root.numberRadius - implicitHeight / 2 }
        }
    }

    Text {
        text: root.units
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.centerY + root.radius * 0.38
        color: "#cfcfcf"
        font.pixelSize: root.width * 0.055
        font.bold: true
    }
}
