// Draws the camera icon. Two ways to run it:
//   osascript -l JavaScript icon/icon.js out.png          the app's icon
//   osascript -l JavaScript icon/icon.js frames/ 60        the recording glow
// The second writes 60 frames, frame-00.png onwards, of the camera fading from
// white to a dull red and back — one cycle, which the app plays round and round
// while it records. The app plays whatever frames it finds, so the glow can be
// changed here and reinstalled without rebuilding the app.
ObjC.import('AppKit')

const WHITE = [1, 1, 1]
const DULL_RED = [0.62, 0.16, 0.16]

function draw(path, body) {
  const size = 1024
  const img = $.NSImage.alloc.initWithSize($.NSMakeSize(size, size))
  img.lockFocus
  // A dark rounded square, the shape of every app icon, inset as Apple's are.
  const inset = 100, r = 185
  const tile = $.NSBezierPath.bezierPathWithRoundedRectXRadiusYRadius($.NSMakeRect(inset, inset, size - 2 * inset, size - 2 * inset), r, r)
  const g = $.NSGradient.alloc.initWithStartingColorEndingColor(
    $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.20, 0.22, 0.26, 1),
    $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.07, 0.08, 0.10, 1))
  g.drawInBezierPathAngle(tile, -90)
  // The camera: a video-camera body and lens, in the colour given.
  $.NSColor.colorWithSRGBRedGreenBlueAlpha(body[0], body[1], body[2], 1).setFill
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
  rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $()).writeToFileAtomically(path, true)
}

function run(argv) {
  if (argv.length < 2) return draw(argv[0], WHITE)
  const dir = argv[0].replace(/\/?$/, '/')
  const count = Number(argv[1])
  for (let i = 0; i < count; i++) {
    // White, to dull red at half way, and back — eased at both ends, so it
    // lingers at each colour rather than bouncing off it.
    const t = (1 - Math.cos((2 * Math.PI * i) / count)) / 2
    const body = WHITE.map((w, k) => w + (DULL_RED[k] - w) * t)
    draw(`${dir}frame-${String(i).padStart(2, '0')}.png`, body)
  }
}
