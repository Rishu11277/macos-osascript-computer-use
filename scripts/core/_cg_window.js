// Prints the CoreGraphics window number of the on-screen window owned by argv[0] whose bounds equal
// argv[1..4] (x y w h, from System Events). Needed for `screencapture -l`, which captures that window
// even when other windows cover it. READ-ONLY. Exit with error if 0 or several windows match.
ObjC.import('CoreGraphics');
function run(argv){
  var owner=argv[0], x=+argv[1], y=+argv[2], w=+argv[3], h=+argv[4];
  var arr=ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo($.kCGWindowListOptionOnScreenOnly|$.kCGWindowListExcludeDesktopElements, 0)));
  var hits=arr.filter(function(i){ var b=i.kCGWindowBounds||{}; return i.kCGWindowOwnerName===owner && i.kCGWindowLayer===0 &&
    Math.abs(b.X-x)<=2 && Math.abs(b.Y-y)<=2 && Math.abs(b.Width-w)<=2 && Math.abs(b.Height-h)<=2; });
  if(hits.length!==1) throw new Error(hits.length+' on-screen windows of '+owner+' match those bounds');
  return String(hits[0].kCGWindowNumber);
}
