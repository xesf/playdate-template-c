#include <stdio.h>
#include <stdlib.h>

#include "pd_api.h"

static int update(void* userdata);

/// @brief Event handler function called by the Playdate system
/// @param pd Pointer to the PlaydateAPI instance
/// @param event The system event type
/// @param arg Additional argument (unused)
/// @return Returns 0 on success
#ifdef _WINDLL
__declspec(dllexport)
#endif
int eventHandler(PlaydateAPI* pd, PDSystemEvent event, uint32_t arg)
{
    if (event == kEventInit)
    {
        // Set the update callback
        pd->system->setUpdateCallback(update, pd);
        // Set initial display refresh rate to 50 Hz / 20 ms
        pd->display->setRefreshRate(50);
    }
    return 0;
}

/// @brief Update callback function called every frame
/// @param userdata Pointer to user data, in this case the PlaydateAPI instance
/// @return Returns 1 to indicate the display should be updated
static int update(void* userdata)
{
    PlaydateAPI* pd = userdata;

    // Clear the screen
    pd->graphics->clear(kColorWhite);

    // Draw "Hello, Playdate!" text
    pd->graphics->drawText("Hello, Playdate!", 16, kASCIIEncoding, 120, 110);

    // Retrieve the crank angle value and draw it on the screen
    float crankAngle = pd->system->getCrankAngle();
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "Crank: %.1f", crankAngle);
    pd->graphics->drawText(buffer, strlen(buffer), kASCIIEncoding, 140, 130);

    // Draw current Frames Per Second (FPS) in the top-left corner
    pd->system->drawFPS(0, 0);

    return 1;
}
