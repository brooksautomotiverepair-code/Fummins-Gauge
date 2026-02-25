import QtQuick 2.15

Item {
    id: root
    width: 0
    height: 0
    visible: false

    // Master toggle from Main
    // false => outputs are forced to 0/false and timer stops
    // true  => demo values run
    property bool enabled: false

    // ===== Gauges (ONLY values Main should read) =====
    property int rpm: 0
    property int speed: 0
    property int coolant: 0
    property int oilPressure: 0
    property int fuelLevel: 0
    property real volts: 0

    // ===== Telltales =====
    property bool leftTurn: false
    property bool rightTurn: false
    property bool highBeam: false

    // ===== Warning lights (add more later) =====
    property bool checkEngine: false
    property bool absLight: false
    property bool batteryLight: false
    property bool parkBrake: false
    property bool lowFuel: false
    property bool pto: false

    // ===== Internals =====
    property int phase: 0
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

    function resetToZeros() {
        rpm = 0
        speed = 0
        coolant = 0
        oilPressure = 0
        fuelLevel = 0
        volts = 0

        leftTurn = false
        rightTurn = false
        highBeam = false

        checkEngine = false
        absLight = false
        batteryLight = false
        parkBrake = false
        lowFuel = false
        pto = false
        // add more resets as you add more lights
    }

    function seedDefaults() {
        phase = 0
        rpm = 800
        speed = 0
        coolant = 160
        oilPressure = 35
        fuelLevel = 75
        volts = 14.1

        leftTurn = false
        rightTurn = false
        highBeam = false

        checkEngine = false
        absLight = false
        batteryLight = false
        parkBrake = false
        lowFuel = false
        pto = false
    }

    // When sim is turned OFF, force everything to 0 immediately
    onEnabledChanged: {
        if (!enabled) {
            demoTimer.stop()
            resetToZeros()
        } else {
            seedDefaults()
            demoTimer.start()
        }
    }

    Timer {
        id: demoTimer
        interval: 33
        repeat: true
        running: false

        onTriggered: {
            phase += 1

            // smooth wave 0..1
            var t = (phase % 360) / 360.0
            var wave = 0.5 - 0.5 * Math.cos(t * Math.PI * 2)

            // Gauges
            rpm = Math.round(800 + wave * (5000 - 800))
            speed = Math.round(clamp((rpm - 800) / 55, 0, 120))

            var t2 = (phase % 900) / 900.0
            var wave2 = 0.5 - 0.5 * Math.cos(t2 * Math.PI * 2)
            coolant = Math.round(160 + wave2 * 60)

            oilPressure = Math.round(20 + wave * 60)           // 20..80
            fuelLevel = Math.round(10 + (1.0 - wave) * 90)     // 100..10
            volts = 13.6 + wave * 1.2                          // 13.6..14.8

            // Telltales
            leftTurn  = ((phase / 12) % 2) < 1
            rightTurn = ((phase / 16) % 2) < 1
            highBeam  = ((phase / 40) % 2) < 1

            // Warnings
            checkEngine = ((phase / 120) % 2) < 1
            absLight = ((phase / 160) % 2) < 1
            batteryLight = false
            lowFuel = fuelLevel <= 15
            parkBrake = ((phase / 240) % 2) < 1
            pto = ((phase / 300) % 2) < 1
        }
    }

    Component.onCompleted: {
        // start clean
        if (!enabled) {
            resetToZeros()
        } else {
            seedDefaults()
            demoTimer.start()
        }
    }
}
