import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: win
    width: 1920
    height: 480
    visible: true
    color: "black"
    title: "Fummins Digital Cluster"

    // =========================
    // Simple toggles
    // =========================
    property bool simEnabled: false
    property bool allLightsTest: false

    // Later: drive this from a real input (headlights on/off)
    property bool headlightsOn: false

    // Day/Night lamp brightness (future)
    property real lampDay: 1.0
    property real lampNight: 0.55
    property bool nightMode: headlightsOn

    // =========================
    // Bulb check / startup
    // =========================
    // (Bulb check duration is now computed to match fade-in + sweep + fade-out)
    property bool bulbCheckActive: false

    SimData {
        id: data
        enabled: win.simEnabled
    }

    // =========================
    // Helpers
    // =========================
    function liveOrZero(v) { return win.simEnabled ? v : 0 }

    function lightOn(rawBool) {
        var base = win.simEnabled ? rawBool : false
        return (win.bulbCheckActive || win.allLightsTest) ? true : base
    }

    // PTO blink helper: ONLY blink when PTO is truly active AND we're not in any test
    function ptoBlink(rawBool) {
        if (win.bulbCheckActive) return false
        if (win.allLightsTest) return false
        return rawBool
    }

    // Lamp test fade multiplier (requires TelltaleIcon.qml to have: property real testBrightness)
    property real lampTestLevel: 0.0
    property int lampFadeInMs: 220
    property int lampFadeOutMs: 260

    // Total sweep time (up + hold + down)
    property int sweepTotalMs: (sweepUpMs + sweepHoldMs + sweepDownMs)

    // How long we hold lamps ON at full brightness during bulb check
    property int lampHoldMs: sweepTotalMs

    // Bulb check length = fade in + hold + fade out
    property int bulbCheckMs: (lampFadeInMs + lampHoldMs + lampFadeOutMs)

    // Helper for each telltale: when in test, use lampTestLevel, otherwise 1.0
    function lampTestBrightness() {
        return (win.bulbCheckActive || win.allLightsTest) ? win.lampTestLevel : 1.0
    }

    // =========================
    // Alert thresholds (adjust anytime)
    // =========================
    property int coolantWarnHigh: 230
    property real voltsWarnLow: 12.0
    property real voltsWarnHigh: 15.5
    property int oilWarnLow: 25
    property int oilWarnHigh: 70

    // Delay alerts until "running" (refine later with real ignition/run state)
    property bool engineRunning: liveOrZero(data.rpm) > 500

    function alertsAllowed() {
        if (booting) return false
        if (phase !== 0) return false
        if (bulbCheckActive) return false
        return engineRunning
    }

    // =========================
    // Boot logo timing
    // =========================
    property bool booting: true
    property int bootPhase: 0

    // Boot logo timing (frames at 16ms)
    property int fadeInDuration: 120
    property int holdDuration: 120
    property int fadeOutDuration: 60

    // =========================
    // Sweep/settle sequence
    // =========================
    // LIVE=0, SWEEP=1, SETTLE=2
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

    // =========================
    // Animations
    // =========================
    SequentialAnimation on sweepT {
        id: sweepAnim
        running: false

        NumberAnimation { to: 0; duration: 1 }

        NumberAnimation {
            to: 1
            duration: win.sweepUpMs
            easing.type: Easing.InOutCubic
        }

        PauseAnimation { duration: win.sweepHoldMs }

        NumberAnimation {
            to: 0
            duration: win.sweepDownMs
            easing.type: Easing.InOutCubic
        }

        onStopped: {
            if (win.phase === 1) {
                win.phase = 2
                win.settleT = 0
                win.takeSnapshot()
                // IMPORTANT: do NOT shut off bulbCheckActive here.
                // Let bulbCheckStop and lampTestAnim fade-out finish cleanly.
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

    // Lamp fade: fade in -> hold for sweep -> fade out
    SequentialAnimation on lampTestLevel {
        id: lampTestAnim
        running: false

        NumberAnimation { to: 0.0; duration: 1 }
        NumberAnimation { to: 1.0; duration: win.lampFadeInMs; easing.type: Easing.InOutQuad }
        PauseAnimation  { duration: win.lampHoldMs }
        NumberAnimation { to: 0.0; duration: win.lampFadeOutMs; easing.type: Easing.InOutQuad }

        onStopped: {
            // Ensure we end solid state at normal brightness
            win.lampTestLevel = 0.0
        }
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

            // Start bulb check + lamp fade synced to sweep
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

    // =========================
    // Boot overlay (IMAGE)
    // =========================
    Rectangle {
        id: bootOverlay
        anchors.fill: parent
        color: "black"
        visible: booting
        z: 9999

        // overall overlay fade-out (optional; you can keep it 1.0 if you want)
        opacity: 1.0

        Image {
            id: bootImg
            anchors.fill: parent
            source: "assets/boot/boot_logo.png"   // <-- change to your qrc path
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            cache: true

            // Fade in -> hold -> fade out using bootPhase
            opacity: {
                // bootPhase counts in "frames" (16ms each in your timer)
                if (bootPhase < fadeInDuration)
                    return bootPhase / fadeInDuration

                if (bootPhase < (fadeInDuration + holdDuration))
                    return 1.0

                // fade out
                var t = (bootPhase - (fadeInDuration + holdDuration)) / fadeOutDuration
                return Math.max(0.0, 1.0 - t)
            }
        }
    }

    // =========================
    // Main layout
    // =========================
    Row {
        id: layout
        anchors.fill: parent
        anchors.topMargin: 35
        anchors.bottomMargin: 15
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 35

        // ---------- LEFT 2x2 ----------
        Item {
            id: leftBlock
            width: 420
            height: parent.height

            Grid {
                id: smallGrid
                anchors.centerIn: parent
                rows: 2
                columns: 2
                rowSpacing: 22
                columnSpacing: 22

                RoundGauge {
                    id: oilGauge
                    width: 190; height: 190
                    minValue: 0; maxValue: 80
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 20
                    units: "OIL"
                    value: gaugeValue(minValue, maxValue, liveOrZero(data.oilPressure), snap.oilPressure)
                    alert: alertsAllowed() && (liveOrZero(data.oilPressure) <= oilWarnLow || liveOrZero(data.oilPressure) >= oilWarnHigh)
                    needleSmooth: (phase === 0)
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85; pivotY: 65
                    needleScale: 0.15
                }

                RoundGauge {
                    id: tempGauge
                    width: 190; height: 190
                    minValue: 100; maxValue: 260
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 40
                    units: "TEMP"
                    value: gaugeValue(minValue, maxValue, liveOrZero(data.coolant), snap.coolant)
                    alert: alertsAllowed() && (liveOrZero(data.coolant) >= coolantWarnHigh)
                    needleSmooth: (phase === 0)
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85; pivotY: 65
                    needleScale: 0.15
                }

                // --- Fuel cell (wrap to allow icons as siblings) ---
                Item {
                    id: fuelCell
                    width: 190
                    height: 190

                    RoundGauge {
                        id: fuelGauge
                        anchors.fill: parent
                        minValue: 0; maxValue: 100
                        majorTicks: 5; minorTicksPerMajor: 4
                        numberEvery: 25
                        units: "FUEL"
                        value: gaugeValue(minValue, maxValue, liveOrZero(data.fuelLevel), snap.fuelLevel)
                        needleSmooth: (phase === 0)
                        needleSource: "assets/needles/Needle2.png"
                        pivotX: 85; pivotY: 65
                        needleScale: 0.15
                    }

                    // LOW FUEL icon (solid only)
                    TelltaleIcon {
                        source: "assets/icons/low_fuel.png"
                        size: 28

                        nightMode: win.nightMode
                        dayBrightness: win.lampDay
                        nightBrightness: win.lampNight
                        testBrightness: win.lampTestBrightness()

                        on: lightOn(data.lowFuel)
                        blink: false

                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 35
                        anchors.bottomMargin: 65
                    }
                }

                RoundGauge {
                    id: voltsGauge
                    width: 190; height: 190
                    minValue: 10; maxValue: 16
                    majorTicks: 4; minorTicksPerMajor: 3
                    numberEvery: 2
                    units: "VOLTS"
                    value: gaugeValue(minValue, maxValue, liveOrZero(data.volts), snap.volts)
                    alert: alertsAllowed() && (liveOrZero(data.volts) <= voltsWarnLow || liveOrZero(data.volts) >= voltsWarnHigh)
                    needleSmooth: (phase === 0)
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85; pivotY: 65
                    needleScale: 0.15
                }
            }

        }

        // ---------- CENTER: SPEEDO ----------
        Item {
            id: centerBlock
            width: 520
            height: parent.height

            RoundGauge {
                id: speedo
                width: 450
                height: 450
                anchors.centerIn: parent

                minValue: 0
                maxValue: 110
                useValueTicks: true
                tickStep: 5
                numberEvery: 10
                units: "MPH"

                value: gaugeValue(minValue, maxValue, liveOrZero(data.speed), snap.speed)
                needleSmooth: (phase === 0)

                needleSource: "assets/needles/Needle2.png"
                pivotX: 65
                pivotY: 65
                needleScale: 0.4

                // HIGH BEAM (inside speedo)
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

                // DIGITAL MPH
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
                            text: Math.round(gaugeValue(speedo.minValue, speedo.maxValue,
                                                        liveOrZero(data.speed), snap.speed))
                            color: "white"
                            font.pixelSize: 56
                            font.bold: true
                        }
                    }

                }
            }

            // ---- Lamps OUTSIDE speedo bezel ----
            // Left turn
            TelltaleIcon {
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

            // Right turn
            TelltaleIcon {
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

            // Park brake (solid only)
            TelltaleIcon {
                source: "assets/icons/park_brake.png"
                size: 38
                nightMode: win.nightMode
                dayBrightness: win.lampDay
                nightBrightness: win.lampNight
                testBrightness: win.lampTestBrightness()

                on: lightOn(data.parkBrake)
                blink: false

                anchors.right: speedo.left
                anchors.bottom: speedo.bottom
                anchors.rightMargin: -18
                anchors.bottomMargin: 32
            }

            // CEL (solid only)
            TelltaleIcon {
                source: "assets/icons/cel.png"
                size: 38
                nightMode: win.nightMode
                dayBrightness: win.lampDay
                nightBrightness: win.lampNight
                testBrightness: win.lampTestBrightness()

                on: lightOn(data.checkEngine)
                blink: false

                anchors.left: speedo.right
                anchors.bottom: speedo.bottom
                anchors.leftMargin: -18
                anchors.bottomMargin: 32
            }
        }

        // ---------- RIGHT: TACH ----------
        Item {
            id: rightBlock
            width: 520
            height: parent.height

            RoundGauge {
                id: tach
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

                value: tachValue(minValue, maxValue)
                needleSmooth: (phase === 0)

                needleSource: "assets/needles/Needle2.png"
                pivotX: 65
                pivotY: 65
                needleScale: 0.4

                // TRIP
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

            // PTO (ONLY one allowed to blink; never during tests)
            TelltaleIcon {
                source: "assets/icons/pto.png"
                size: 40

                nightMode: win.nightMode
                dayBrightness: win.lampDay
                nightBrightness: win.lampNight
                testBrightness: win.lampTestBrightness()

                on: lightOn(data.pto)
                blink: ptoBlink(data.pto)

                anchors.left: tach.left
                anchors.top: tach.top
                anchors.leftMargin: -45
                anchors.topMargin: 80
            }
        }
    }
}
