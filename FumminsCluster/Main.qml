import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: win
    width: 1920
    height: 480
    visible: true
    color: "black"
    title: "Fummins Digital Cluster"

    SimData { id: data }

    // ===== Boot / Startup Controller =====
    property bool booting: true
    property int bootPhase: 0
    property real bootRpm: 0
    property real liveRpm: booting ? bootRpm : data.rpm

    property int fadeInDuration: 120
    property int holdDuration: 120
    property int fadeOutDuration: 60

    // ===== Gauge Sweep =====
    property bool startupSweep: false
    property real sweepT: 0          // 0..1
    property int sweepUpMs: 1500     // 1.5s up
    property int sweepDownMs: 1500   // 1.5s down
    property int sweepHoldMs: 0      // 0 = no pause at max

    function sweepValue(minV, maxV) {
        return minV + sweepT * (maxV - minV)
    }

    // Animate sweepT smoothly (no restart() needed)
    SequentialAnimation on sweepT {
        id: sweepAnim
        running: win.startupSweep

        // ensure we begin from 0
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

        onStopped: win.startupSweep = false
    }

    Component.onCompleted: {
        data.enabled = false
        bootTimer.start()
    }

    Timer {
        id: bootTimer
        interval: 16
        repeat: true
        running: false
        onTriggered: {
            bootPhase += 1

            if (bootPhase <= 60) {
                bootRpm = 0
                data.leftTurn = false
                data.rightTurn = false
                data.highBeam = false
                return
            }

            if (bootPhase <= 140) {
                var tUp = (bootPhase - 60) / 80.0
                bootRpm = Math.round(tUp * 4000)
                return
            }

            if (bootPhase <= 200) {
                var tDn = (bootPhase - 140) / 60.0
                bootRpm = Math.round(4000 - tDn * (4000 - 800))
                return
            }

            if (bootPhase <= 260) {
                var on = ((bootPhase / 8) % 2) < 1
                data.leftTurn = on
                data.rightTurn = on
                data.highBeam = on
                bootRpm = 800
                return
            }

            // Boot finished
            booting = false
            bootTimer.stop()
            data.enabled = true

            // Start smooth sweep (no timers / restart needed)
            sweepT = 0
            startupSweep = true
        }
    }

    // ===== Boot overlay =====
    Rectangle {
        anchors.fill: parent
        color: "black"
        visible: booting
        z: 9999

        opacity: bootPhase < (fadeInDuration + holdDuration)
            ? 1.0
            : Math.max(0.0,
                1.0 - (bootPhase - (fadeInDuration + holdDuration)) / fadeOutDuration)

        Text {
            anchors.centerIn: parent
            text: "FUMMINS"
            color: "blue"
            font.pixelSize: 250

            opacity: bootPhase < fadeInDuration
                ? (bootPhase / fadeInDuration)
                : 1.0
        }
    }

    // ===== Top telltale strip (placeholder) =====
    Row {
        spacing: 18
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10

        Text { text: data.leftTurn ? "◀" : "";  color: "green"; font.pixelSize: 42 }
        Text { text: data.highBeam ? "🔵" : ""; color: "deepskyblue"; font.pixelSize: 26 }
        Text { text: data.rightTurn ? "▶" : ""; color: "green"; font.pixelSize: 42 }
    }

    // ===== Main layout =====
    Row {
        id: layout
        anchors.fill: parent
        anchors.topMargin: 35
        anchors.bottomMargin: 15
        anchors.leftMargin: 25
        anchors.rightMargin: 25
        spacing: 35

        // LEFT: 2x2 small gauges
        Item {
            width: 420
            height: parent.height

            Grid {
                anchors.centerIn: parent
                rows: 2
                columns: 2
                rowSpacing: 22
                columnSpacing: 22

                // Oil Pressure (example)
                RoundGauge {
                    width: 190; height: 190
                    minValue: 0; maxValue: 80
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 20
                    units: "OIL"
                    value: startupSweep ? sweepValue(minValue, maxValue) : 40
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85
                    pivotY: 65
                    needleScale: 0.15
                }

                // Coolant Temp
                RoundGauge {
                    width: 190; height: 190
                    minValue: 100; maxValue: 260
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 40
                    units: "TEMP"
                    value: startupSweep ? sweepValue(minValue, maxValue) : data.coolant
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85
                    pivotY: 65
                    needleScale: 0.15
                }

                // Fuel
                RoundGauge {
                    width: 190; height: 190
                    minValue: 0; maxValue: 100
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 25
                    units: "FUEL"
                    value: startupSweep ? sweepValue(minValue, maxValue) : 60
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85
                    pivotY: 65
                    needleScale: 0.15
                }

                // Volts
                RoundGauge {
                    width: 190; height: 190
                    minValue: 10; maxValue: 16
                    majorTicks: 4; minorTicksPerMajor: 3
                    numberEvery: 2
                    units: "VOLTS"
                    value: startupSweep ? sweepValue(minValue, maxValue) : 14.2
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85
                    pivotY: 65
                    needleScale: 0.15
                }
            }
        }

        // CENTER: Speedometer big
        Item {
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
                units: ""
                value: startupSweep ? sweepValue(minValue, maxValue) : data.speed
                needleSource: "assets/needles/Needle2.png"
                pivotX: 65
                pivotY: 65
                needleScale: 0.4
            }

            // Digital MPH like the reference
            Column {
                anchors.horizontalCenter: speedo.horizontalCenter
                anchors.verticalCenter: speedo.verticalCenter
                anchors.verticalCenterOffset: 70
                spacing: 2

                Text {
                    text: data.speed
                    color: "white"
                    font.pixelSize: 70
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "MPH"
                    color: "#cccccc"
                    font.pixelSize: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // RIGHT: Tach big
        Item {
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

                value: startupSweep ? sweepValue(minValue, maxValue) : liveRpm
                needleSource: "assets/needles/Needle2.png"
                pivotX: 65
                pivotY: 65
                needleScale: 0.4
            }

            // Time / Odo area like the reference (placeholder)
            Column {
                anchors.horizontalCenter: tach.horizontalCenter
                anchors.verticalCenter: tach.verticalCenter
                anchors.verticalCenterOffset: 115
                spacing: 3

                Text {
                    text: "A 01480 mi"
                    color: "#cccccc"
                    font.pixelSize: 18
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
