#!/usr/bin/env python3
# Makes SDL 2.0.12 build against the iOS 9.3 SDK and run on iOS 5.1.1.
import os
import sys

root = sys.argv[1]


def patch(rel, old, new):
    path = os.path.join(root, rel)
    with open(path) as f:
        text = f.read()
    if new in text:
        return
    if old not in text:
        sys.exit("patch_sdl: pattern not found in " + rel + ":\n" + old)
    with open(path, "w") as f:
        f.write(text.replace(old, new, 1))


ca = "src/audio/coreaudio/SDL_coreaudio.m"

# setCategory:mode:options:error: is iOS 10 and not declared in the 9.3 SDK; iOS 5 only has setCategory:error:.
patch(ca, "if ([session respondsToSelector:@selector(setCategory:mode:options:error:)]) {\n"
          "            if (![session setCategory:category mode:mode options:options error:&err]) {",
      "if ([session respondsToSelector:@selector(setCategory:withOptions:error:)]) {\n"
      "            (void)mode;\n"
      "            if (![session setCategory:category withOptions:options error:&err]) {")

# The interruption notification constant appeared in iOS 6. A NULL name would subscribe to every notification.
patch(ca, "        if (open) {\n            SDLInterruptionListener *listener",
      "        if (open && &AVAudioSessionInterruptionNotification != NULL) {\n            SDLInterruptionListener *listener")

# Preferred sample rate API is iOS 6+; on iOS 5 keep the requested rate and let CoreAudio convert.
patch(ca, "        [session setPreferredSampleRate:this->spec.freq error:nil];\n"
          "        this->spec.freq = (int)session.sampleRate;",
      "        if ([session respondsToSelector:@selector(setPreferredSampleRate:error:)]) {\n"
      "            [session setPreferredSampleRate:this->spec.freq error:nil];\n"
      "            this->spec.freq = (int)session.sampleRate;\n"
      "        }")

# Home indicator selectors are iOS 11 and missing from the 9.3 SDK headers.
patch("src/video/uikit/SDL_uikitviewcontroller.m",
      "            [viewcontroller setNeedsUpdateOfHomeIndicatorAutoHidden];\n"
      "            [viewcontroller setNeedsUpdateOfScreenEdgesDeferringSystemGestures];",
      "            [viewcontroller performSelector:@selector(setNeedsUpdateOfHomeIndicatorAutoHidden)];\n"
      "            [viewcontroller performSelector:@selector(setNeedsUpdateOfScreenEdgesDeferringSystemGestures)];")

# Player index uses GCController even when MFi support is compiled out.
js = "src/joystick/iphoneos/SDL_sysjoystick.m"
patch(js, "    return device ? (int)device->controller.playerIndex : -1;",
      "#ifdef SDL_JOYSTICK_MFI\n    return device ? (int)device->controller.playerIndex : -1;\n#else\n    return -1;\n#endif")
patch(js, "    if (device) {\n        device->controller.playerIndex = player_index;\n    }",
      "#ifdef SDL_JOYSTICK_MFI\n    if (device) {\n        device->controller.playerIndex = player_index;\n    }\n#endif")

print("patch_sdl: done")
