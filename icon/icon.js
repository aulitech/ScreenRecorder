ObjC.import('AppKit')
function run(argv) {
  const size = 1024
  const img = $.NSImage.alloc.initWithSize($.NSMakeSize(size, size))
  img.lockFocus
  // A dark rounded square, the shape of every app icon, inset as Apple's are.
  const inset = 100, r = 185
  const body = $.NSBezierPath.bezierPathWithRoundedRectXRadiusYRadius($.NSMakeRect(inset, inset, size - 2 * inset, size - 2 * inset), r, r)
  const g = $.NSGradient.alloc.initWithStartingColorEndingColor(
    $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.20, 0.22, 0.26, 1),
    $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.07, 0.08, 0.10, 1))
  g.drawInBezierPathAngle(body, -90)
  // The camera: a white video-camera body and lens.
  $.NSColor.whiteColor.setFill
  $.NSBezierPath.bezierPathWithRoundedRectXRadiusYRadius($.NSMakeRect(215, 340, 420, 330), 60, 60).fill
  const lens = $.NSBezierPath.bezierPath
  lens.moveToPoint($.NSMakePoint(655, 450))
  lens.lineToPoint($.NSMakePoint(810, 360))
  lens.lineToPoint($.NSMakePoint(810, 650))
  lens.lineToPoint($.NSMakePoint(655, 560))
  lens.closePath
  lens.fill
  // A red record light on the camera's body.
  $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.94, 0.20, 0.20, 1).setFill
  $.NSBezierPath.bezierPathWithOvalInRect($.NSMakeRect(268, 555, 70, 70)).fill
  img.unlockFocus
  const rep = $.NSBitmapImageRep.imageRepWithData(img.TIFFRepresentation)
  rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $()).writeToFileAtomically(argv[0], true)
}
