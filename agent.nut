// Agent code for PillBox

const TIME_OFFSET = -5;
local prescriptionTop;
local prescriptionBottom;
local currentTime

function init()
{
    device.on("box lid event", onBoxLidEvent);
    http.onrequest(requestHandler);
}

function loop()
{
    currentTime = date();
    currentTime.hour = (currentTime.hour + TIME_OFFSET + 24) % 24;
    //server.log(currentTime.hour);
    /*if (prescriptionTop != null)
    {
        server.log(prescriptionTop.getNextTime().hour);
        server.log(prescriptionTop.getNextTime().min);
    }*/
    if (prescriptionTop != null && currentTime.hour == prescriptionTop.getNextTime().hour 
        && currentTime.min == prescriptionTop.getNextTime().min)
    {
        server.log("Alert for top prescription");
        sendAlert(true);
        prescriptionTop.giveDose();
    }
    if (prescriptionBottom != null && currentTime.hour == prescriptionBottom.getNextTime().hour 
        && currentTime.min == prescriptionBottom.getNextTime().min)
    {
        server.log("Alert for bottom prescription");
        sendAlert(false);
        prescriptionBottom.giveDose();
    }
    imp.wakeup(1, loop);
}

// Event Handlers
function onBoxLidEvent(isOpen)
{
    if (isOpen)
    {
        server.log("Box has been opened");
    }
    else
    {
        server.log("Box has been closed");
    }
}
// Converts a String in "HH:MM" format to at time table in date() format
function stringToTime(input)
{
    local timeTable = {};
    timeTable.hour <- input.slice(0,2).tointeger();
    timeTable.min <- input.slice(3,5).tointeger();
    return timeTable;
}
// HTTP request handler
function requestHandler(request, response)
{
    server.log("Request received");
    try 
    {
        // Demo
        if ("demo" in request.query) 
        {
            if ("top" in request.query)
                sendAlert(true);
            if ("bottom" in request.query)
                sendAlert(false);
        }
        else
        {
            // Set prescriptions
            if ("topPrescription" in request.query)
            {
                if ("topTime" in request.query)
                {
                    server.log("Setting prescription top to a List prescription");
                    local timeStringList = split(request.query.topTime, ",");
                    local timeIntList = array();
                    foreach(input in timeStringList)
                    {
                        timeIntList.append(stringToTime(input));
                    }
                    if (timeIntList.len() == 1)
                    {
                        server.log("Special case: Setting prescription bottom to a Freq prescription with period 24h");
                        prescriptionTop = PrescriptionFreq(timeIntList[0], 23, 59);
                    }
                    else
                    {
                        prescriptionTop = PrescriptionList(timeIntList);
                    }
                }
                else if("topStart" in request.query && "topFreq" in request.query)
                {
                    server.log("Setting prescription top to a Freq prescription");
                    // topFreq is decimal hours
                    local freqFloat = request.query.topFreq.tofloat();
                    
                    prescriptionTop = PrescriptionFreq(stringToTime(request.query.topStart), freqFloat.tointeger(),
                        ((freqFloat - freqFloat.tointeger()) * 60).tointeger())
                }
                else
                {
                    server.log("Invalid Top Prescription");
                }
            }
            if ("bottomPrescription" in request.query)
            {
                if ("bottomTime" in request.query)
                {
                    server.log("Setting prescription bottom to a List prescription");
                    local timeStringList = split(request.query.bottomTime, ",");
                    local timeIntList = array();
                    foreach(input in timeStringList)
                    {
                        timeIntList.append(stringToTime(input));
                    }
                    if (timeIntList.len() == 1)
                    {
                        server.log("Special case: Setting prescription bottom to a Freq prescription with period 24h");
                        prescriptionBottom = PrescriptionFreq(timeIntList[0], 23, 59);
                    }
                    else
                    {
                        prescriptionBottom = PrescriptionList(timeIntList);
                    }
                }
                else if("bottomStart" in request.query && "bottomFreq" in request.query)
                {
                    server.log("Setting prescription bottom to a Freq prescription");
                    // topFreq is decimal hours
                    local freqFloat = request.query.topFreq.tofloat();
                    
                    prescriptionBottom = PrescriptionFreq(stringToTime(request.query.bottomStart), freqFloat.tointeger(),
                        ((freqFloat - freqFloat.tointeger()) * 60).tointeger())
                }
                else
                {
                    server.log("Invalid Bottom Prescription");
                }
            }
        }
        response.send(200, "OK"); // "200: OK" is standard return message
    } catch (ex) {
        response.send(500, ("Agent Error: " + ex)); // Send 500 response if error occured
    }
}
// Tell device to start an alert, with boolean for which prescription
function sendAlert(isTop)
{
    server.log("Sending alert");
    device.send("Alert", isTop)
}

// A list-type prescription, which calculates doses based on a list of times
class PrescriptionList
{
    _currentIndex = -1;
    _timeList = null;
    
    constructor(timeList) 
    {
        _timeList = timeList;
        local currentDate = date();
        currentDate.hour = (currentDate.hour + TIME_OFFSET + 24) % 24;
        // If the current time is after the last time in the list, use the first in the list
        if (compareDate(timeList[timeList.len() - 1], currentDate))
        {
            _currentIndex = 0;
        }
        else
        {
            // Iterate to find the first time that is after the current time
            for (_currentIndex = 0; compareDate(currentDate, timeList[_currentIndex]); _currentIndex++);
        }
    }
    // Tests if a time1 is before time2
    function compareDate(time1, time2)
    {
        if (time1.hour == time2.hour)
            return time1.min < time2.min
        else
            return time1.hour < time2.hour
    }
    function getNextTime()
    {
        return _timeList[_currentIndex];
    }
    function giveDose()
    {
        // Calculate time for next dose
        _currentIndex = (_currentIndex + 1) % _timeList.len();
        return _timeList[_currentIndex];
    }
}
// A frequency-type prescription, which calculates doses based on a set time between doses
class PrescriptionFreq
{
    _nextDose = -1;
    _freqHours = 0;
    _freqMinutes = 0;
    
    constructor(nextDose, freqHours, freqMinutes) 
    {
        _nextDose = nextDose;
        _freqHours = freqHours;
        _freqMinutes = freqMinutes;
    }
    function getNextTime()
    {
        return _nextDose;
    }
    function giveDose()
    {
        // Calculate time for next dose
        local newMin = (_nextDose.min + _freqMinutes) % 60;
        local newHour = (_nextDose.hour + (_nextDose.min + _freqMinutes) / 60 + _freqHours) % 24;
        _nextDose.hour = newHour;
        _nextDose.min = newMin;
        return _nextDose;
    }
}

// Main
init();
loop();