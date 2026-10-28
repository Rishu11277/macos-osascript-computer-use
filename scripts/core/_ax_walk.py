# Fast UI search via the macOS Accessibility C API (AXUIElement*), ~1000x faster than System Events
# Apple Events on large web views (SPIKE: 1,022 elements in 0.08 s vs >60 s). Breadth-first, bounded by
# --depth and --max-nodes. Matching: role = AXRole or AXRoleDescription; label = AXTitle/AXDescription/
# AXHelp/AXValue(text) [AXValue only with --contains], case-insensitive (exact unless contains).
# Usage: python3 -I _ax_walk.py PID WINDOW_INDEX ROLE NAME MODE MAX DEPTH MAX_NODES list|press
# list: READ-ONLY. press: performs AXPress on the single match (refuses on 0 or several).
import ctypes, ctypes.util, sys
AS = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices")
CF = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreFoundation"))
vp = ctypes.c_void_p
CF.CFStringCreateWithCString.restype = vp; CF.CFStringCreateWithCString.argtypes = [vp, ctypes.c_char_p, ctypes.c_uint32]
CF.CFArrayGetCount.restype = ctypes.c_long; CF.CFArrayGetCount.argtypes = [vp]
CF.CFArrayGetValueAtIndex.restype = vp; CF.CFArrayGetValueAtIndex.argtypes = [vp, ctypes.c_long]
CF.CFGetTypeID.restype = ctypes.c_ulong; CF.CFGetTypeID.argtypes = [vp]
CF.CFStringGetTypeID.restype = ctypes.c_ulong
CF.CFStringGetCString.restype = ctypes.c_bool; CF.CFStringGetCString.argtypes = [vp, ctypes.c_char_p, ctypes.c_long, ctypes.c_uint32]
AS.AXUIElementCreateApplication.restype = vp; AS.AXUIElementCreateApplication.argtypes = [ctypes.c_int]
AS.AXUIElementCopyAttributeValue.restype = ctypes.c_int32; AS.AXUIElementCopyAttributeValue.argtypes = [vp, vp, ctypes.POINTER(vp)]
AS.AXUIElementPerformAction.restype = ctypes.c_int32; AS.AXUIElementPerformAction.argtypes = [vp, vp]
AS.AXIsProcessTrusted.restype = ctypes.c_bool
UTF8 = 0x08000100
_keys = {}
def key(s):
    if s not in _keys: _keys[s] = CF.CFStringCreateWithCString(None, s.encode(), UTF8)
    return _keys[s]
def text(v):
    if not v or CF.CFGetTypeID(v) != CF.CFStringGetTypeID(): return ""
    buf = ctypes.create_string_buffer(8192); CF.CFStringGetCString(v, buf, 8192, UTF8)
    return buf.value.decode("utf-8", "replace")
def attr(el, name):
    out = vp(); return out.value if AS.AXUIElementCopyAttributeValue(el, key(name), ctypes.byref(out)) == 0 else None
def die(msg, code): sys.stderr.write(msg + "\n"); sys.exit(code)
pid, wi, role, name, mode, maxm, depth, maxnodes, action = sys.argv[1:10]
pid, wi, maxm, depth, maxnodes = int(pid), int(wi), int(maxm), int(depth), int(maxnodes)
if not AS.AXIsProcessTrusted(): die("Accessibility not granted to this host (-25211)", 1)
app = AS.AXUIElementCreateApplication(pid)
wins = attr(app, "AXWindows")
if not wins or CF.CFArrayGetCount(wins) < wi: die(f"process has no window {wi} (-1719)", 1)
lc = str.lower; rq, nq = lc(role), lc(name)
q, seen, hits, truncated = [(CF.CFArrayGetValueAtIndex(wins, wi - 1), 0)], 0, [], False
while q:
    el, d = q.pop(0)
    kids = attr(el, "AXChildren")
    if not kids: continue
    for i in range(CF.CFArrayGetCount(kids)):
        if seen >= maxnodes: truncated = True; break
        k = CF.CFArrayGetValueAtIndex(kids, i); seen += 1
        r, rd = text(attr(k, "AXRole")), text(attr(k, "AXRoleDescription"))
        ok = not rq or lc(r) == rq or lc(rd) == rq
        labels = None
        if ok and nq:
            labels = [text(attr(k, a)) for a in ("AXTitle", "AXDescription", "AXHelp")] + ([text(attr(k, "AXValue"))] if mode == "contains" else [])
            ok = any((nq in lc(l)) if mode == "contains" else (lc(l) == nq) for l in labels)
        if ok:
            hits.append((k, r, rd))
            if action == "list" and len(hits) >= maxm: q = []; break
        if d + 1 < depth: q.append((k, d + 1))
    if truncated: break
note = f" (searched {seen} elements, depth<={depth}{', node limit hit' if truncated else ''})"
if action == "press":
    if not hits: die("no element matches" + note + " (-1728)", 1)
    if len(hits) > 1: die(f"{len(hits)} elements match; narrow the query" + note + " (-1719)", 1)
    err = AS.AXUIElementPerformAction(hits[0][0], key("AXPress"))
    if err != 0: die(f"AXPress failed with AXError {err}" + note, 1)
    print("pressed: AXPress" + note); sys.exit(0)
print(f"matches: {len(hits)}" + note)
for n, (k, r, rd) in enumerate(hits, 1):
    t, ds, v = text(attr(k, "AXTitle")), text(attr(k, "AXDescription")), text(attr(k, "AXValue"))
    v = (v[:80] + "…") if len(v) > 80 else v
    print(f"[{n}] {rd or r} | name={t or '-'} | desc={ds or '-'} | value={v or '-'}")
