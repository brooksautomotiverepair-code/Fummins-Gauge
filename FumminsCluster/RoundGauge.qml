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

    // Styling
    property bool thousandsLabels: false

    GaugeFace {
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

    }

    GaugeNeedle {
        anchors.fill: parent
        source: root.needleSource
        pivotX: root.pivotX
        pivotY: root.pivotY
        needleScale: root.needleScale   //
        value: root.value
        minValue: root.minValue
        maxValue: root.maxValue
        minAngle: root.startAngle
        maxAngle: root.endAngle
    }
}
