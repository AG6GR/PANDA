// Device code for PillBox

//#require "APDS9007.class.nut:1.0.0"
#require "LPS25H.class.nut:1.0.0"
#require "Si702x.class.nut:1.0.0"

local lightSensor
local pressureSensor
local tempHumidSensor
local isOpen
local isOpenNow
const LIGHT_THRESH = 75;

function init()
{
    local lightOutputPin = hardware.pin5
    lightOutputPin.configure(ANALOG_IN)
    local lightEnablePin = hardware.pin7
    lightEnablePin.configure(DIGITAL_OUT, 1)
    lightSensor = APDS9007(lightOutputPin, 47000, lightEnablePin)
    isOpen = lightSensor.read() > LIGHT_THRESH;
    
    hardware.i2c89.configure(CLOCK_SPEED_400_KHZ)
    pressureSensor = LPS25H(hardware.i2c89)
    
    tempHumidSensor = Si702x(hardware.i2c89)
    
    server.log("Init finished, starting loop");
}
function loop()
{
    server.log(lightSensor.read())
    isOpenNow = lightSensor.read() > LIGHT_THRESH;
    if (isOpenNow != isOpen)
    {
        agent.send("box lid event", isOpenNow)
    }
    isOpen = isOpenNow;
    imp.wakeup(1, loop);
}

/* Adapted from https://github.com/electricimp/APDS9007/blob/v1.0/APDS9007.class.nut 
    modified sample speed */
class APDS9007 {
    static WAIT_BEFORE_READ = 0.0;
    RLOAD = null; // value of load resistor on ALS (device has current output)

    _als_pin            = null;
    _als_en             = null;
    _points_per_read    = null;

    // -------------------------------------------------------------------------
    constructor(als_pin, rload, als_en = null, points_per_read = 10) {
        _als_pin = als_pin;
        _als_en = als_en;
        RLOAD = rload;
        _points_per_read = points_per_read * 1.0; //force to a float
    }

    // -------------------------------------------------------------------------
    // read the ALS and return value in lux
    function read() {
        if (_als_en) {
            _als_en.write(1);
            imp.sleep(WAIT_BEFORE_READ);
        }
        local Vpin = 0;
        local Vcc = 0;
        // average several readings for improved precision
        for (local i = 0; i < _points_per_read; i++) {
            Vpin += _als_pin.read();
            Vcc += hardware.voltage();
        }
        Vpin = (Vpin * 1.0) / _points_per_read;
        Vcc = (Vcc * 1.0) / _points_per_read;
        Vpin = (Vpin / 65535.0) * Vcc;
        local Iout = (Vpin / RLOAD) * 1000000.0; // current in µA
        if (_als_en) _als_en.write(0);
        return (math.pow(10.0,(Iout/10.0)));
    }
}

//---Main---
init();
// Wait 3 sec to start up
imp.wakeup(3, loop);