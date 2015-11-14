// Agent code for PillBox

function init()
{
    device.on("box lid event", onBoxLidEvent);
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

// Main
init();