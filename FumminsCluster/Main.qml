
import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: win
    width: 1920
    height: 480
    visible: true
    color: "black"
    title: "Fummins Digital Cluster"

    property bool simEnabled: false
    property bool allLightsTest: false
    property bool headlightsOn: false

    property real lampDay: 1.0
    property real lampNight: 0.55
    property bool nightMode: headlightsOn

    // Primary UX mode. "cluster" = full instruments, "map" = map first + compact overlays.
    property string displayMode: "cluster"
    property bool mapMode: displayMode === "map"

    // Shared style presets to make future visual updates easier.
    property var smallGaugeStyle: ({
        needleSource: "assets/needles/Needle2.png",
        pivotX: 85,
        pivotY: 65,
        needleScale: 0.15,
        tickColor: "#f2f2f2",
        minorTickColor: "#b8b8b8",
        showRings: true,
        outerRingColor: "#242424",
        innerRingColor: "#0f0f0f"
    })

    property var primaryGaugeStyle: ({
        needleSource: "assets/needles/Needle2.png",
        pivotX: 65,
        pivotY: 65,
        needleScale: 0.4,
        useValueTicks: true,
        tickStep: 5,
        mediumTickLen: 26,
        mediumTickWidth: 3,
        tickColor: "#ffffff",
        minorTickColor: "#9f9f9f"
    })

    property var tachGaugeStyle: ({
        needleSource: "assets/needles/Needle2.png",
        pivotX: 65,
        pivotY: 65,
        needleScale: 0.4,
        tickColor: "#ffffff",
        minorTickColor: "#b5b5b5"
    })

    property var compactMapGaugeStyle: ({
        needleSource: "assets/needles/Needle2.png",
        pivotX: 65,
        pivotY: 65,
        needleScale: 0.18,
        tickColor: "#f6f6f6",
        minorTickColor: "#8f8f8f",
        showRings: true,
        outerRingColor: "#202020",
        innerRingColor: "#111111"
    })

    property bool bulbCheckActive: false

    SimData {
        id: data
        enabled: win.simEnabled
    }

    function liveOrZero(v) { return win.simEnabled ? v : 0 }

    function lightOn(rawBool) {
        var base = win.simEnabled ? rawBool : false
        return (win.bulbCheckActive || win.allLightsTest) ? true : base
    }

    function ptoBlink(rawBool) {
        if (win.bulbCheckActive) return false
        if (win.allLightsTest) return false
        return rawBool
    }

    property real lampTestLevel: 0.0
    property int lampFadeInMs: 220
    property int lampFadeOutMs: 260

    property int sweepTotalMs: (sweepUpMs + sweepHoldMs + sweepDownMs)
    property int lampHoldMs: sweepTotalMs
    property int bulbCheckMs: (lampFadeInMs + lampHoldMs + lampFadeOutMs)

    function lampTestBrightness() {
        return (win.bulbCheckActive || win.allLightsTest) ? win.lampTestLevel : 1.0
    }

    property int coolantWarnHigh: 230
    property real voltsWarnLow: 12.0
    property real voltsWarnHigh: 15.5
    property int oilWarnLow: 25
    property int oilWarnHigh: 70

    property bool engineRunning: liveOrZero(data.rpm) > 500

    function alertsAllowed() {
        if (booting) return false
        if (phase !== 0) return false
        if (bulbCheckActive) return false
        return engineRunning
    }

    property bool booting: true
    property int bootPhase: 0

    property int fadeInDuration: 120
    property int holdDuration: 120
    property int fadeOutDuration: 60

    property int phase: 0
    property real sweepT: 0
    property real settleT: 0

    property int sweepUpMs: 1500
    property int sweepDownMs: 1500
    property int sweepHoldMs: 0
    property int settleMs: 700

    property var snap: ({
        rpm: 0,
        speed: 0,
        coolant: 0,
        oilPressure: 0,
        fuelLevel: 0,
        volts: 0
    })

    function takeSnapshot() {
        snap = {
            rpm: liveOrZero(data.rpm),
            speed: liveOrZero(data.speed),
            coolant: liveOrZero(data.coolant),
            oilPressure: liveOrZero(data.oilPressure),
            fuelLevel: liveOrZero(data.fuelLevel),
            volts: liveOrZero(data.volts)
        }
    }

    function gaugeValue(minV, maxV, liveV, snapV) {
        if (phase === 1) return minV + sweepT * (maxV - minV)
        if (phase === 2) return minV + settleT * (snapV - minV)
        return liveV
    }

    function tachValue(minV, maxV) {
        if (booting) return 0
        return gaugeValue(minV, maxV, liveOrZero(data.rpm), snap.rpm)
    }

    SequentialAnimation on sweepT {
        id: sweepAnim
        running: false

        NumberAnimation { to: 0; duration: 1 }
        NumberAnimation { to: 1; duration: win.sweepUpMs; easing.type: Easing.InOutCubic }
        PauseAnimation { duration: win.sweepHoldMs }
        NumberAnimation { to: 0; duration: win.sweepDownMs; easing.type: Easing.InOutCubic }

        onStopped: {
            if (win.phase === 1) {
                win.phase = 2
                win.settleT = 0
                win.takeSnapshot()
                settleAnim.start()
            }
        }
    }

    NumberAnimation on settleT {
        id: settleAnim
        running: false
        to: 1
        duration: win.settleMs
        easing.type: Easing.InOutCubic
        onStopped: {
            if (win.phase === 2) win.phase = 0
        }
    }

    SequentialAnimation on lampTestLevel {
        id: lampTestAnim
        running: false

        NumberAnimation { to: 0.0; duration: 1 }
        NumberAnimation { to: 1.0; duration: win.lampFadeInMs; easing.type: Easing.InOutQuad }
        PauseAnimation { duration: win.lampHoldMs }
        NumberAnimation { to: 0.0; duration: win.lampFadeOutMs; easing.type: Easing.InOutQuad }

        onStopped: win.lampTestLevel = 0.0
    }

    Component.onCompleted: bootTimer.start()

    Timer {
        id: bootTimer
        interval: 16
        repeat: true
        running: false
        onTriggered: {
            bootPhase += 1

            var bootTotal = fadeInDuration + holdDuration + fadeOutDuration
            if (bootPhase < bootTotal)
                return

            booting = false
            bootTimer.stop()

            bulbCheckActive = true
            lampTestLevel = 0.0
            lampTestAnim.start()
            bulbCheckStop.restart()

            phase = 1
            sweepT = 0
            settleT = 0
            sweepAnim.start()
        }
    }

    Timer {
        id: bulbCheckStop
        interval: win.bulbCheckMs
        repeat: false
        running: false
        onTriggered: win.bulbCheckActive = false
    }

    Rectangle {
        id: modePill
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 22
        anchors.topMargin: 14
        width: 212
        height: 42
        radius: 21
        color: "#202020"
        border.color: "#3b3b3b"
        border.width: 1
        z: 30

        Text {
            anchors.centerIn: parent
            text: win.mapMode ? "MAP MODE" : "CLUSTER MODE"
            color: "#f2f2f2"
            font.pixelSize: 16
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: win.displayMode = win.mapMode ? "cluster" : "map"
        }
    }

    Rectangle {
        id: bootOverlay
        anchors.fill: parent
        color: "black"
        visible: booting
        z: 9999

        Image {
            id: bootImg
            anchors.fill: parent
            source: "assets/boot/boot_logo.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            cache: true

            opacity: {
                if (bootPhase < fadeInDuration)
                    return bootPhase / fadeInDuration

                if (bootPhase < (fadeInDuration + holdDuration))
                    return 1.0

                var t = (bootPhase - (fadeInDuration + holdDuration)) / fadeOutDuration
                return Math.max(0.0, 1.0 - t)
            }
        }
    }

    Row {
        id: layout
        anchors.fill: parent
        anchors.topMargin: 35
        anchors.bottomMargin: 15
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: win.mapMode ? 16 : 35

        Item {
            id: leftBlock
            width: win.mapMode ? 270 : 420
            height: parent.height

            Grid {
                id: smallGrid
                anchors.centerIn: parent
                rows: win.mapMode ? 4 : 2
                columns: 2
                rowSpacing: win.mapMode ? 16 : 22
                columnSpacing: win.mapMode ? 16 : 22

                RoundGauge {
                    id: oilGauge
                    width: win.mapMode ? 120 : 190
                    height: width
                    minValue: 0; maxValue: 80
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 20
                    units: "OIL"
                    style: win.smallGaugeStyle
                    value: gaugeValue(minValue, maxValue, liveOrZero(data.oilPressure), snap.oilPressure)
                    alert: alertsAllowed() && (liveOrZero(data.oilPressure) <= oilWarnLow || liveOrZero(data.oilPressure) >= oilWarnHigh)
                    needleSmooth: (phase === 0)
                }

                RoundGauge {
                    id: tempGauge
                    width: win.mapMode ? 120 : 190
                    height: width
                    minValue: 100; maxValue: 260
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 40
                    units: "TEMP"
                    style: win.smallGaugeStyle
                    value: gaugeValue(minValue, maxValue, liveOrZero(data.coolant), snap.coolant)
                    alert: alertsAllowed() && (liveOrZero(data.coolant) >= coolantWarnHigh)
                    needleSmooth: (phase === 0)
                }

                Item {
                    id: fuelCell
                    width: win.mapMode ? 120 : 190
                    height: width

                    RoundGauge {
                        id: fuelGauge
                        anchors.fill: parent
                        minValue: 0; maxValue: 100
                        majorTicks: 5; minorTicksPerMajor: 4
                        numberEvery: 25
                        units: "FUEL"
                        style: win.smallGaugeStyle
                        value: gaugeValue(minValue, maxValue, liveOrZero(data.fuelLevel), snap.fuelLevel)
                        needleSmooth: (phase === 0)
                    }

                    TelltaleIcon {
                        source: "assets/icons/low_fuel.png"
                        size: win.mapMode ? 20 : 28

                        nightMode: win.nightMode
                        dayBrightness: win.lampDay
                        nightBrightness: win.lampNight
                        testBrightness: win.lampTestBrightness()

                        on: lightOn(data.lowFuel)
                        blink: false

                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: win.mapMode ? 14 : 35
                        anchors.bottomMargin: win.mapMode ? 24 : 65
                    }
                }

                RoundGauge {
                    id: voltsGauge
                    width: win.mapMode ? 120 : 190
                    height: width
                    minValue: 10; maxValue: 16
                    majorTicks: 4; minorTicksPerMajor: 3
                    numberEvery: 2
                    units: "VOLTS"
                    style: win.smallGaugeStyle
                    value: gaugeValue(minValue, maxValue, liveOrZero(data.volts), snap.volts)
                    alert: alertsAllowed() && (liveOrZero(data.volts) <= voltsWarnLow || liveOrZero(data.volts) >= voltsWarnHigh)
                    needleSmooth: (phase === 0)
                }
            }
        }

        Item {
            id: centerBlock
            width: win.mapMode ? (layout.width - leftBlock.width - rightBlock.width - layout.spacing * 2) : 520
            height: parent.height

            RoundGauge {
                id: speedo
                visible: !win.mapMode
                width: 450
                height: 450
                anchors.centerIn: parent

                minValue: 0
                maxValue: 110
                style: win.primaryGaugeStyle
                useValueTicks: true
                tickStep: 5
                numberEvery: 10
                units: "MPH"

                value: gaugeValue(minValue, maxValue, liveOrZero(data.speed), snap.speed)
                needleSmooth: (phase === 0)

                TelltaleIcon {
                    source: "assets/icons/high_beam.png"
                    size: 38
                    nightMode: win.nightMode
                    dayBrightness: win.lampDay
                    nightBrightness: win.lampNight
                    testBrightness: win.lampTestBrightness()
                    on: lightOn(data.highBeam)
                    blink: false

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 110
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 150
                    spacing: 6

                    Rectangle {
                        width: 140
                        height: 67
                        radius: 14
                        color: "#2b2b2b"
                        border.width: 1
                        border.color: "#4a4a4a"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: parent.height * 0.40
                            radius: 14
                            color: "#ffffff"
                            opacity: 0.08
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(gaugeValue(speedo.minValue, speedo.maxValue, liveOrZero(data.speed), snap.speed))
                            color: "white"
                            font.pixelSize: 56
                            font.bold: true
                        }
                    }
                }
            }

            Rectangle {
                id: mapSurface
                visible: win.mapMode
                anchors.fill: parent
                radius: 20
                color: "#13171d"
                border.color: "#3c4f67"
                border.width: 2

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 14
                    radius: 14
                    color: "#182433"
                    opacity: 0.75
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Android Auto / Maps Surface"
                    color: "#dce9ff"
                    font.pixelSize: 30
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 28
                    text: "Touch-first area reserved for navigation + apps"
                    color: "#b9cbe8"
                    font.pixelSize: 18
                }

                RoundGauge {
                    width: 160
                    height: 160
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 18
                    anchors.topMargin: 18

                    minValue: 0
                    maxValue: 110
                    numberEvery: 20
                    majorTicks: 7
                    minorTicksPerMajor: 1
                    units: "MPH"
                    style: win.compactMapGaugeStyle
                    value: gaugeValue(minValue, maxValue, liveOrZero(data.speed), snap.speed)
                    needleSmooth: (phase === 0)
                }

                RoundGauge {
                    width: 160
                    height: 160
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 18
                    anchors.topMargin: 18

                    minValue: 0
                    maxValue: 5000
                    numberEvery: 1000
                    majorTicks: 6
                    minorTicksPerMajor: 2
                    units: "RPM"
                    thousandsLabels: true
                    showRedline: true
                    redlineFrom: 4200
                    redlineTo: 5000
                    style: win.compactMapGaugeStyle
                    value: tachValue(minValue, maxValue)
                    needleSmooth: (phase === 0)
                }
            }

            TelltaleIcon {
                visible: !win.mapMode
                source: "assets/icons/turn_left.png"
                size: 42
                nightMode: win.nightMode
                dayBrightness: win.lampDay
                nightBrightness: win.lampNight
                testBrightness: win.lampTestBrightness()
                on: lightOn(data.leftTurn)
                blink: false

                anchors.right: speedo.left
                anchors.top: speedo.top
                anchors.rightMargin: -22
                anchors.topMargin: 18
            }

            TelltaleIcon {
                visible: !win.mapMode
                source: "assets/icons/turn_right.png"
                size: 42
                nightMode: win.nightMode
                dayBrightness: win.lampDay
                nightBrightness: win.lampNight
                testBrightness: win.lampTestBrightness()
                on: lightOn(data.rightTurn)
                blink: false

                anchors.left: speedo.right
                anchors.top: speedo.top
                anchors.leftMargin: -22
                anchors.topMargin: 18
            }

            Row {
                visible: win.mapMode
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 18
                spacing: 18

                TelltaleIcon {
                    source: "assets/icons/high_beam.png"
                    size: 30
                    nightMode: win.nightMode
                    dayBrightness: win.lampDay
                    nightBrightness: win.lampNight
                    testBrightness: win.lampTestBrightness()
                    on: lightOn(data.highBeam)
                    blink: false
                }
                TelltaleIcon {
                    source: "assets/icons/turn_left.png"
                    size: 30
                    nightMode: win.nightMode
                    dayBrightness: win.lampDay
                    nightBrightness: win.lampNight
                    testBrightness: win.lampTestBrightness()
                    on: lightOn(data.leftTurn)
                    blink: false
                }
                TelltaleIcon {
                    source: "assets/icons/turn_right.png"
                    size: 30
                    nightMode: win.nightMode
                    dayBrightness: win.lampDay
                    nightBrightness: win.lampNight
                    testBrightness: win.lampTestBrightness()
                    on: lightOn(data.rightTurn)
                    blink: false
                }
            }
        }

        Item {
            id: rightBlock
            width: win.mapMode ? 270 : 520
            height: parent.height

            RoundGauge {
                id: tach
                visible: !win.mapMode
                width: 420
                height: 420
                anchors.centerIn: parent

                minValue: 0
                maxValue: 5000
                majorTicks: 6
                minorTicksPerMajor: 4
                numberEvery: 1000
                units: "RPM"
                thousandsLabels: true
                showRedline: true
                redlineFrom: 4200
                redlineTo: 5000
                style: win.tachGaugeStyle

                value: tachValue(minValue, maxValue)
                needleSmooth: (phase === 0)

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 150
                    spacing: 6

                    Rectangle {
                        width: 175
                        height: 55
                        radius: 12
                        color: "#2b2b2b"
                        border.width: 1
                        border.color: "#4a4a4a"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: parent.height * 0.40
                            radius: 12
                            color: "#ffffff"
                            opacity: 0.08
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "A 01480 mi"
                            color: "white"
                            font.pixelSize: 22
                            font.bold: true
                        }
                    }

                    Text {
                        text: "TRIP"
                        color: "#cfcfcf"
                        font.pixelSize: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 14
                visible: win.mapMode

                TelltaleIcon {
                    source: "assets/icons/park_brake.png"
                    size: 34
                    nightMode: win.nightMode
                    dayBrightness: win.lampDay
                    nightBrightness: win.lampNight
                    testBrightness: win.lampTestBrightness()
                    on: lightOn(data.parkBrake)
                    blink: false
                }

                TelltaleIcon {
                    source: "assets/icons/cel.png"
                    size: 34
                    nightMode: win.nightMode
                    dayBrightness: win.lampDay
                    nightBrightness: win.lampNight
                    testBrightness: win.lampTestBrightness()
                    on: lightOn(data.checkEngine)
                    blink: false
                }
            }

            TelltaleIcon {
                visible: !win.mapMode
                source: "assets/icons/park_brake.png"
                size: 38
                nightMode: win.nightMode
                dayBrightness: win.lampDay
                nightBrightness: win.lampNight
                testBrightness: win.lampTestBrightness()
                on: lightOn(data.parkBrake)
                blink: false

                anchors.right: tach.left
                anchors.bottom: tach.bottom
                anchors.rightMargin: -18
                anchors.bottomMargin: 32
            }

            TelltaleIcon {
                visible: !win.mapMode
                source: "assets/icons/cel.png"
                size: 38
                nightMode: win.nightMode
                dayBrightness: win.lampDay
                nightBrightness: win.lampNight
                testBrightness: win.lampTestBrightness()
                on: lightOn(data.checkEngine)
                blink: false

                anchors.left: tach.right
                anchors.bottom: tach.bottom
                anchors.leftMargin: -18
                anchors.bottomMargin: 32
            }

            TelltaleIcon {
                source: "assets/icons/pto.png"
                size: win.mapMode ? 34 : 40
                nightMode: win.nightMode
                dayBrightness: win.lampDay
                nightBrightness: win.lampNight
                testBrightness: win.lampTestBrightness()
                on: lightOn(data.pto)
                blink: ptoBlink(data.pto)

                anchors.left: win.mapMode ? undefined : tach.left
                anchors.top: win.mapMode ? undefined : tach.top
                anchors.leftMargin: win.mapMode ? 0 : -45
                anchors.topMargin: win.mapMode ? 0 : 80
                anchors.horizontalCenter: win.mapMode ? parent.horizontalCenter : undefined
                anchors.bottom: win.mapMode ? parent.bottom : undefined
                anchors.bottomMargin: win.mapMode ? 18 : 0
            }
        }
    }
}
