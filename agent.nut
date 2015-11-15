// Agent code for PillBox

function init()
{
    device.on("box lid event", onBoxLidEvent);
    http.onrequest(requestHandler);
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
// HTTP request handler
function requestHandler(request, response)
{
    server.log("Request received");
    try {
        // Demo
        if ("demo" in request.query && "top" in request.query && "bottom" in request.query) 
        {
            sendAlert(request.query["top"].tointeger() != 0, request.query["bottom"].tointeger() != 0);
        }
        response.send(200, "OK"); // "200: OK" is standard return message
    } catch (ex) {
        response.send(500, ("Agent Error: " + ex)); // Send 500 response if error occured
    }
}

// Tell device to start an alert, with the respective top and bottom LED states
function sendAlert(top, bottom)
{
    server.log("Sending alert");
    device.send("Alert", [top, bottom])
}

// Main
init();