// Names that appeared after SDL 2.0.12, which is the newest SDL that runs on iOS 5.
#pragma once

#include <SDL_pixels.h>

#ifndef SDL_PIXELFORMAT_XRGB8888
#define SDL_PIXELFORMAT_XRGB8888 SDL_PIXELFORMAT_RGB888
#define SDL_PIXELFORMAT_XBGR8888 SDL_PIXELFORMAT_BGR888
#endif
