#!/usr/bin/env python3
# Minimal msgfmt replacement: compiles a .po file into a GNU .mo file in the given 8-bit encoding,
# like files/lang/Makefile does with "iconv | msgfmt". Fuzzy entries are skipped.
# Usage: po2mo.py input.po output.mo cp1251
import ast
import struct
import sys

src, dst, encoding = sys.argv[1], sys.argv[2], sys.argv[3]


def parse(path):
    entries = []
    current = {}
    field = None
    fuzzy = False

    def flush():
        nonlocal current, fuzzy
        if "msgid" in current and not fuzzy:
            entries.append(current)
        current = {}
        fuzzy = False

    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                flush()
                field = None
                continue
            if line.startswith("#,") and "fuzzy" in line:
                fuzzy = True
                continue
            if line.startswith("#"):
                continue
            if line.startswith('"'):
                current[field] += ast.literal_eval(line)
                continue
            key, _, value = line.partition(" ")
            if key in ("msgctxt", "msgid") and ("msgstr" in current or "msgstr[0]" in current):
                flush()
            field = key
            current[field] = ast.literal_eval(value)
    flush()
    return entries


messages = {}
for e in parse(src):
    msgid = e["msgid"]
    if "msgid_plural" in e:
        msgid += "\0" + e["msgid_plural"]
        forms = []
        i = 0
        while "msgstr[%d]" % i in e:
            forms.append(e["msgstr[%d]" % i])
            i += 1
        msgstr = "\0".join(forms)
    else:
        msgstr = e.get("msgstr", "")
    if "msgctxt" in e:
        msgid = e["msgctxt"] + "\x04" + msgid
    if msgid and not msgstr.replace("\0", ""):
        continue  # untranslated
    if msgid == "":
        msgstr = msgstr.replace("charset=UTF-8", "charset=" + encoding.upper())
    messages[msgid.encode(encoding, "replace")] = msgstr.encode(encoding, "replace")

keys = sorted(messages)
count = len(keys)
header_size = 7 * 4
ids_offset = header_size
strs_offset = ids_offset + count * 8
data_offset = strs_offset + count * 8

ids, strs, data = b"", b"", b""
for k in keys:
    ids += struct.pack("<II", len(k), data_offset + len(data))
    data += k + b"\0"
for k in keys:
    v = messages[k]
    strs += struct.pack("<II", len(v), data_offset + len(data))
    data += v + b"\0"

with open(dst, "wb") as f:
    f.write(struct.pack("<IIIIIII", 0x950412DE, 0, count, ids_offset, strs_offset, 0, 0))
    f.write(ids + strs + data)
print("%s: %d messages" % (dst, count))
