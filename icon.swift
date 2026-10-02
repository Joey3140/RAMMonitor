// Generates icon_1024.png: flat white squircle with the app's five-segment
// memory donut (same colors/order/inner-radius ratio as PieChartView).
// Run: swift icon.swift
import AppKit

let canvas = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: canvas, pixelsHigh: canvas,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Standard macOS icon grid: 824x824 squircle centered on 1024 canvas.
let squircle = NSBezierPath(
    roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824),
    xRadius: 185, yRadius: 185
)
NSColor.white.setFill()
squircle.fill()

// App Memory, Wired, Compressed, Cached Files, Free — clockwise from 12
// o'clock, matching the popover chart. Fractions picked for a pleasant icon.
let segments: [(fraction: CGFloat, color: NSColor)] = [
    (0.44, .systemBlue),
    (0.07, .systemRed),
    (0.06, .systemOrange),
    (0.23, .systemYellow),
    (0.20, .systemGreen),
]

let center = NSPoint(x: 512, y: 512)
let outerR: CGFloat = 300
let innerR: CGFloat = outerR * 0.55   // same donut thickness ratio as the app
let gap: CGFloat = 3                  // degrees of breathing room per boundary

var startDeg: CGFloat = 90            // 12 o'clock, AppKit angles are CCW from +x
for seg in segments {
    let sweep = seg.fraction * 360
    let a0 = startDeg - gap / 2
    let a1 = startDeg - sweep + gap / 2
    let path = NSBezierPath()
    path.appendArc(withCenter: center, radius: outerR, startAngle: a0, endAngle: a1, clockwise: true)
    path.appendArc(withCenter: center, radius: innerR, startAngle: a1, endAngle: a0, clockwise: false)
    path.close()
    seg.color.setFill()
    path.fill()
    startDeg -= sweep
}

NSGraphicsContext.restoreGraphicsState()
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "icon_1024.png"))
print("wrote icon_1024.png")
