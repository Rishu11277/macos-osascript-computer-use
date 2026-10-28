# Prints the keyboard-focused UI element of a process: "<AXRole>\t<editable 0|1>".
# editable = the element's AXValue is settable, or it is a text role. Used by type_text/paste_text to refuse
# typing when no text field has focus. READ-ONLY.  Usage: python3 -I _ax_focus.py PID
import ctypes, ctypes.util, sys
AS = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices")
CF = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreFoundation"))
vp = ctypes.c_void_p
CF.CFStringCreateWithCString.restype = vp; CF.CFStringCreateWithCString.argtypes = [vp, ctypes.c_char_p, ctypes.c_uint32]
CF.CFGetTypeID.restype = ctypes.c_ulong; CF.CFGetTypeID.argtypes = [vp]; CF.CFStringGetTypeID.restype = ctypes.c_ulong
CF.CFStringGetCString.restype = ctypes.c_bool; CF.CFStringGetCString.argtypes = [vp, ctypes.c_char_p, ctypes.c_long, ctypes.c_uint32]
AS.AXUIElementCreateApplication.restype = vp; AS.AXUIElementCreateApplication.argtypes = [ctypes.c_int]
AS.AXUIElementCopyAttributeValue.restype = ctypes.c_int32; AS.AXUIElementCopyAttributeValue.argtypes = [vp, vp, ctypes.POINTER(vp)]
AS.AXUIElementIsAttributeSettable.restype = ctypes.c_int32; AS.AXUIElementIsAttributeSettable.argtypes = [vp, vp, ctypes.POINTER(ctypes.c_bool)]
AS.AXIsProcessTrusted.restype = ctypes.c_bool
def key(s): return CF.CFStringCreateWithCString(None, s.encode(), 0x08000100)
def text(v):
    if not v or CF.CFGetTypeID(v) != CF.CFStringGetTypeID(): return ""
    b = ctypes.create_string_buffer(512); CF.CFStringGetCString(v, b, 512, 0x08000100); return b.value.decode()
if not AS.AXIsProcessTrusted(): sys.stderr.write("Accessibility not granted (-25211)\n"); sys.exit(1)
app = AS.AXUIElementCreateApplication(int(sys.argv[1]))
f = vp()
if AS.AXUIElementCopyAttributeValue(app, key("AXFocusedUIElement"), ctypes.byref(f)) != 0 or not f.value:
    print("none\t0"); sys.exit(0)
r = vp(); AS.AXUIElementCopyAttributeValue(f.value, key("AXRole"), ctypes.byref(r)); role = text(r.value)
ok = ctypes.c_bool(False); AS.AXUIElementIsAttributeSettable(f.value, key("AXValue"), ctypes.byref(ok))
TEXT_ROLES = {"AXTextField", "AXTextArea", "AXComboBox", "AXSearchField", "AXSecureTextField"}
print(f"{role or 'unknown'}\t{1 if (role in TEXT_ROLES or ok.value) else 0}")
