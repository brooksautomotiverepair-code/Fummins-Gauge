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

            booting = false
            bootTimer.stop()
            data.enabled = true
        }
    }

    // ===== Boot overlay =====
    Rectangle {
        anchors.fill: parent
        color: "black"
        visible: booting
        opacity: bootPhase < 120 ? 1.0 : Math.max(0.0, 1.0 - (bootPhase - 120) / 40.0)

        Text {
            anchors.centerIn: parent
            text: "FORD"
            color: "white"
            font.pixelSize: 84
            opacity: bootPhase < 60 ? (bootPhase / 60.0) : 1.0
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
                    value: 40
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85
                    pivotY: 65
                    needleScale: 0.15   // ✅ small gauge needle size
                }

                // Coolant Temp
                RoundGauge {
                    width: 190; height: 190
                    minValue: 100; maxValue: 260
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 40
                    units: "TEMP"
                    value: data.coolant
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85
                    pivotY: 65
                    needleScale: 0.15   // ✅ small gauge needle size
                }

                // Fuel
                RoundGauge {
                    width: 190; height: 190
                    minValue: 0; maxValue: 100
                    majorTicks: 5; minorTicksPerMajor: 4
                    numberEvery: 25
                    units: "FUEL"
                    value: 60
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85
                    pivotY: 65
                    needleScale: 0.15   // ✅ small gauge needle size
                }

                // Volts
                RoundGauge {
                    width: 190; height: 190
                    minValue: 10; maxValue: 16
                    majorTicks: 4; minorTicksPerMajor: 3
                    numberEvery: 2
                    units: "VOLTS"
                    value: 14.2
                    needleSource: "assets/needles/Needle2.png"
                    pivotX: 85
                    pivotY: 65
                    needleScale: 0.15   // ✅ small gauge needle size
                }
            }
        }

        // CENTER: Speedometer big
        Item {
            width: 520
            height: parent.height

            RoundGauge {
                id: speedo
                width: 420
                height: 420
                anchors.centerIn: parent

                minValue: 0
                maxValue: 110
                tickStep: 5        //  Refer to GaugeFace.qml for Info
                numberEvery: 10
                units: ""                // keep face clean like OEM
                value: data.speed
                needleSource: "assets/needles/Needle2.png"
                pivotX: 65
                pivotY: 65
                needleScale: .4   //  gauge needle size
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
                maxValue: 5000          // ✅ was 4000
                majorTicks: 6           // ✅ 0,1,2,3,4,5
                minorTicksPerMajor: 4   // 4 minor ticks between each 1000
                numberEvery: 1000
                units: "RPM"
                thousandsLabels: true

                showRedline: true
                redlineFrom: 4200       // tweak as you like
                redlineTo: 5000

                value: liveRpm
                needleSource: "assets/needles/Needle2.png"
                pivotX: 65
                pivotY: 65
                needleScale: .4   // ✅ small gauge needle size
            }

            // Time / Odo area like the reference (placeholder)
            Column {
                anchors.horizontalCenter: tach.horizontalCenter
                anchors.verticalCenter: tach.verticalCenter
                anchors.verticalCenterOffset: 115
                spacing: 3

                Text {
                    text: "12:09"
                    color: "#cccccc"
                    font.pixelSize: 26
                    anchors.horizontalCenter: parent.horizontalCenter
                }
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
