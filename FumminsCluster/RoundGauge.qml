import QtQuick 2.15

Item {
    id: root
    width: 380
    height: 380

    // Added For Gauge ticks
    property real tickStep: 1
    property real mediumTickLen: 0
    property real mediumTickWidth: 0
    property bool useValueTicks: false

    // Face config
    property real value: 0
    property real minValue: 0
    property real maxValue: 100
    property real startAngle: 135
    property real endAngle: 405

    property int majorTicks: 7
    property int minorTicksPerMajor: 4
    property real numberEvery: 20
    property string units: ""

    property real redlineFrom: 0
    property real redlineTo: 0
    property bool showRedline: false

    // Needle
    property url needleSource: ""
    property real pivotX: 0
    property real pivotY: 0
    property real needleScale: 1.0
    property bool needleSmooth: true

    // Flashing Alerts
    property bool alert: false
    property color alertColor: "#ff2a2a"
    property int alertFlashMs: 450
    property real alertRingWidth: 7

    // Styling
    property bool thousandsLabels: false

    // ✅ Anything you place inside RoundGauge { ... } will go UNDER the needle now
    default property alias underNeedleChildren: underNeedleLayer.data

    GaugeFace {
        id: face
        anchors.fill: parent
        minValue: root.minValue
        maxValue: root.maxValue
        majorTicks: root.majorTicks
        minorTicksPerMajor: root.minorTicksPerMajor
        startAngle: root.startAngle
        endAngle: root.endAngle
        units: root.units
        numberEvery: root.numberEvery
        thousandsLabels: root.thousandsLabels
        hideZeroLabel: false
        showRedline: root.showRedline
        redlineFrom: root.redlineFrom
        redlineTo: root.redlineTo
        tickStep: root.tickStep
        useValueTicks: root.useValueTicks
        z: 0
    }

    // ✅ Under-needle layer (MPH / TRIP plates live here)
    Item {
        id: underNeedleLayer
        anchors.fill: parent
        z: 5
    }

    GaugeNeedle {
        id: needle
        anchors.fill: parent
        source: root.needleSource
        pivotX: root.pivotX
        pivotY: root.pivotY
        needleScale: root.needleScale
        value: root.value
        minValue: root.minValue
        maxValue: root.maxValue
        minAngle: root.startAngle
        maxAngle: root.endAngle
        smoothEnabled: root.needleSmooth
        z: 10
    }

    //Flashing Alert ring
    Canvas {
        id: alertRing
        anchors.fill: parent
        visible: root.alert
        opacity: root.alert ? 1.0 : 0.0
        z: 20

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var r = Math.min(width, height) * 0.485

            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            // Soft outer glow stroke
            ctx.beginPath()
            ctx.strokeStyle = "rgba(255, 42, 42, 0.35)"
            ctx.lineWidth = root.alertRingWidth + 6
            ctx.shadowColor = "rgba(255, 42, 42, 0.35)"
            ctx.shadowBlur = 6
            ctx.arc(width/2, height/2, r, 0, Math.PI * 2, false)
            ctx.stroke()

            // Crisp inner stroke
            ctx.beginPath()
            ctx.shadowBlur = 0
            ctx.strokeStyle = root.alertColor
            ctx.lineWidth = root.alertRingWidth
            ctx.arc(width/2, height/2, r, 0, Math.PI * 2, false)
            ctx.stroke()
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    SequentialAnimation {
        running: root.alert
        loops: Animation.Infinite
        NumberAnimation { target: alertRing; property: "opacity"; from: 0.25; to: 0.85; duration: root.alertFlashMs }
        NumberAnimation { target: alertRing; property: "opacity"; from: 0.85; to: 0.25; duration: root.alertFlashMs }
    }
}
