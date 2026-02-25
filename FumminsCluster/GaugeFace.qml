import QtQuick 2.15

Item {
    id: root
    width: 400
    height: 400

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

    // Dial Tick Mods
    property bool useValueTicks: false     // default keeps old behavior


    // Labeling
    property string units: "RPM"
    property bool showNumbers: true
    property real numberEvery: 500

    // Ford-ish formatting
    property bool thousandsLabels: true     // 1000->"1", 2000->"2"
    property bool hideZeroLabel: true       // hide the "0" label on tach

    // Redline
    property real redlineFrom: 3200
    property real redlineTo: 4000
    property bool showRedline: true

    // Styling
    property color tickColor: "white"
    property color minorTickColor: "#bdbdbd"
    property color numberColor: "white"
    property color redlineColor: "#c21d1d"

    // Tick styling by value (3-tier ticks)
    // (1) Tiny tick every 1 mph, Medium tick every 5 mph, Big tick every 10 mph
    // (2) Small tick every 2 mph, Medium at 10? Actually no — because 5 isn’t hit, Big every 10
    // (5) Medium ticks at 5,15,25..., Big ticks at 10,20,30..., No tiny ticks at all.

    property real tickStep: 1              // 1 = tiny ticks every 1 unit, 5 = only 5/10 ticks
    property real mediumTickLen: radius * 0.12
    property real mediumTickWidth: 3

    // Hybrid texture
    property url baseTexture: ""

    // Tuning knobs
    property real majorTickLen: radius * 0.16
    property real minorTickLen: radius * 0.09
    property real majorTickWidth: 4
    property real minorTickWidth: 2
    property real numberRadius: radius * 0.70
    property real redlineRadius: radius * 0.93
    property real redlineWidth: 6

    // Rim rings (OEM-ish)
    property bool showRings: true
    property color outerRingColor: "#2a2a2a"
    property color innerRingColor: "#111111"

    function lerp(a, b, t) { return a + (b - a) * t; }
    function deg2rad(d) { return d * Math.PI / 180.0; }
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

    function valueToAngle(v) {
        var t = (clamp(v, minValue, maxValue) - minValue) / (maxValue - minValue)
        return lerp(startAngle, endAngle, t)
    }

    function formatLabel(v) {
        if (hideZeroLabel && v === 0) return ""
        if (thousandsLabels) {
            if (v >= 1000) return (v / 1000).toFixed(0)   // 1000->"1"
            return v.toFixed(0)
        }
        return v.toFixed(0)
    }

    Image {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        source: root.baseTexture
        visible: root.baseTexture !== ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    // Tick marks + redline arc + rings
    Canvas {
        id: dial
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            // Rings (subtle bezel / shadow)
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
                var a = deg2rad(angleDeg)
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

            // Ticks
            if (root.useValueTicks) {

                //  NEW: value-based ticks (big 10s, medium 5s, small others)
                for (var v = root.minValue; v <= root.maxValue + 0.0001; v += root.tickStep) {

                    var ang = root.valueToAngle(v)

                    var len = root.minorTickLen
                    var thick = root.minorTickWidth
                    var col = root.minorTickColor

                    if (v % 5 === 0) {
                        len = root.mediumTickLen
                        thick = root.mediumTickWidth
                        col = root.tickColor
                    }
                    if (v % 10 === 0) {
                        len = root.majorTickLen
                        thick = root.majorTickWidth
                        col = root.tickColor
                    }

                    drawTick(ang, len, thick, col)
                }

            } else {

                //  OLD: major + minor ticks (what your other gauges expect)
                var majors = root.majorTicks
                for (var i = 0; i < majors; i++) {
                    var tMajor = i / (majors - 1)
                    var angMajor = lerp(root.startAngle, root.endAngle, tMajor)

                    drawTick(angMajor, root.majorTickLen, root.majorTickWidth, root.tickColor)

                    if (i < majors - 1) {
                        for (var m = 1; m <= root.minorTicksPerMajor; m++) {
                            var tMinor = (i + m / (root.minorTicksPerMajor + 1)) / (majors - 1)
                            var angMinor = lerp(root.startAngle, root.endAngle, tMinor)
                            drawTick(angMinor, root.minorTickLen, root.minorTickWidth, root.minorTickColor)
                        }
                    }
                }
            }

            // Redline arc (painted look)
            if (root.showRedline) {
                var a1 = deg2rad(root.valueToAngle(root.redlineFrom))
                var a2 = deg2rad(root.valueToAngle(root.redlineTo))

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

    // Numbers
    Repeater {
        model: root.showNumbers ? Math.floor((root.maxValue - root.minValue) / root.numberEvery) + 1 : 0
        delegate: Text {
            property real v: root.minValue + index * root.numberEvery
            property real ang: root.valueToAngle(v)
            property real a: root.deg2rad(ang)

            text: root.formatLabel(v)
            visible: text !== ""
            color: root.numberColor
            font.pixelSize: root.width * 0.070
            font.bold: true

            x: root.centerX + Math.cos(a) * root.numberRadius - width / 2
            y: root.centerY + Math.sin(a) * root.numberRadius - height / 2
        }
    }

    // Units label (small, like OEM)
    Text {
        text: root.units
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.centerY + root.radius * 0.38
        color: "#cfcfcf"
        font.pixelSize: root.width * 0.055
        font.bold: true
    }
}
