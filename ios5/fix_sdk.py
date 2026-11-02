#!/usr/bin/env python3
# Makes a copy of the iOS 9.3 SDK whose .tbd stubs list only ARM architectures.
# The newer ld64 treats stubs that also list i386/x86_64 as "built for iOS Simulator"
# and refuses to resolve symbols from them when linking for armv7.
import os
import re
import shutil
import sys

src, dst = sys.argv[1], sys.argv[2]
if not os.path.isdir(dst):
    shutil.copytree(src, dst, symlinks=True)

list_re = re.compile(r"\[([^\[\]]*)\]")


def strip_intel(match):
    items = [i.strip() for i in match.group(1).split(",")]
    if not any(i in ("i386", "x86_64") for i in items):
        return match.group(0)
    kept = [i for i in items if i not in ("i386", "x86_64")]
    return "[ " + ", ".join(kept) + " ]"


count = 0
for root, _, files in os.walk(dst):
    for name in files:
        if not name.endswith(".tbd"):
            continue
        path = os.path.join(root, name)
        if os.path.islink(path):
            continue
        with open(path) as f:
            text = f.read()
        fixed = list_re.sub(strip_intel, text)
        if fixed != text:
            with open(path, "w") as f:
                f.write(fixed)
            count += 1
print("patched", count, "tbd files")

# The Theos stub of libsystem_platform lacks the optimized string routines that live there on iOS 9.
# At runtime they are resolved through libSystem's re-exports on any iOS version.
platform_symbols = [
    "_bzero", "_memchr", "_memcmp", "_memcpy", "_memmove", "_memset", "_memset_pattern4",
    "_memset_pattern8", "_memset_pattern16", "_strchr", "_strcmp", "_strncmp", "_strnlen", "___bzero",
]
platform = os.path.join(dst, "usr/lib/system/libsystem_platform.tbd")
with open(platform) as f:
    text = f.read()
if "_memcpy," not in text:
    entry = "exports:\n  - archs:              [ armv7, armv7s, arm64 ]\n    symbols:            [ " + ", ".join(platform_symbols) + " ]\n"
    text = text.replace("exports:\n", entry, 1)
    with open(platform, "w") as f:
        f.write(text)
    print("added string routines to libsystem_platform.tbd")
