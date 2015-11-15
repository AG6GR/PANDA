// Device code for PillBox

local lightOutputPin;
local isOpen;
local alert;
local topLedState;
local bottomLedState;
const LIGHT_THRESH = 50000;

// Turns both LEDs off to save power
function ledOff()
{
    hardware.pin1.write(0);
    hardware.pin2.write(0);
    hardware.pin7.write(0);
    hardware.pin8.write(0);
}
// Turn on the leds, corresponding to state variables
function ledOn()
{
    // Top LED
    hardware.pin7.write(topLedState? 1 : 0);
    hardware.pin8.write(topLedState? 0 : 1);
    
    // Bottom LED
    hardware.pin1.write(bottomLedState? 1 : 0);
    hardware.pin2.write(bottomLedState? 0 : 1);
}
// Turns on the beeper
function startBeep()
{
    hardware.pin9.write(0.5);
    //imp.wakeup(1, endBeep)
}
// Stops the beeper
function endBeep()
{
    hardware.pin9.write(0.0);
}
// Handler for Alert message from agent
function onAlert(isTop)
{
    alert = true;
    server.log("Lighting led");
    if (isTop)
        topLedState = true;
    else
        bottomLedState = true;
    ledOn();
    startBeep();
}
// Initialization, run once at start
function init()
{
    // Light sensor
    lightOutputPin = hardware.pin5
    lightOutputPin.configure(ANALOG_IN)
    isOpen = lightOutputPin.read() < LIGHT_THRESH;
    
    // LEDs
    hardware.pin1.configure(DIGITAL_OUT);
    hardware.pin2.configure(DIGITAL_OUT);
    hardware.pin7.configure(DIGITAL_OUT);
    hardware.pin8.configure(DIGITAL_OUT);
    ledOff();
    topLedState = false;
    bottomLedState = false;
    
    // Beeper
    hardware.pin9.configure(PWM_OUT, 0.0005, 0.0);
    hardware.pin9.write(0.0);
    
    // Alert handling
    alert = false;
    agent.on("Alert", onAlert);
    
    server.log("Init finished, starting loop");
}
function loop()
{
    //server.log(lightOutputPin.read())
    local isOpenNow = lightOutputPin.read() < LIGHT_THRESH;
    if (isOpenNow && alert)
    {
        endBeep();
        alert = false;
    }
    if (isOpenNow != isOpen)
    {
        agent.send("box lid event", isOpenNow)
        if (!isOpenNow)
        {
            topLedState = false;
            bottomLedState = false;
            ledOff();
        }
        else
        {
            ledOn();
        }
    }
    isOpen = isOpenNow;
    imp.wakeup(1, loop);
}

init();
// Wait 1 sec to start up
imp.wakeup(1, loop);