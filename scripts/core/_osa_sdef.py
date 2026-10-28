# Prints an app's scripting definition (sdef XML) via the OpenScripting API (OSACopyScriptingDefinitionFromURL).
# Works without Xcode and covers legacy Cocoa apps (scriptSuite/scriptTerminology, e.g. TextEdit). READ-ONLY.
# Usage: python3 -I _osa_sdef.py /path/App.app   (exit 1 if the app exposes no dictionary)
import ctypes, ctypes.util, sys
cf = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreFoundation"))
osa = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/Carbon.framework/Frameworks/OpenScripting.framework/OpenScripting")
cf.CFURLCreateFromFileSystemRepresentation.restype = ctypes.c_void_p
cf.CFURLCreateFromFileSystemRepresentation.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_long, ctypes.c_bool]
osa.OSACopyScriptingDefinitionFromURL.restype = ctypes.c_int32
osa.OSACopyScriptingDefinitionFromURL.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.POINTER(ctypes.c_void_p)]
cf.CFDataGetLength.restype = ctypes.c_long; cf.CFDataGetLength.argtypes=[ctypes.c_void_p]
cf.CFDataGetBytePtr.restype = ctypes.c_void_p; cf.CFDataGetBytePtr.argtypes=[ctypes.c_void_p]
path = sys.argv[1].encode()
url = cf.CFURLCreateFromFileSystemRepresentation(None, path, len(path), True)
out = ctypes.c_void_p()
err = osa.OSACopyScriptingDefinitionFromURL(url, 0, ctypes.byref(out))
if err != 0 or not out.value: sys.stderr.write(f"OSACopyScriptingDefinitionFromURL error {err}\n"); sys.exit(1)
n = cf.CFDataGetLength(out); sys.stdout.write(ctypes.string_at(cf.CFDataGetBytePtr(out), n).decode("utf-8","replace"))
