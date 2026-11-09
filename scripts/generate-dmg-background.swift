#!/usr/bin/env swift
// Generates scripts/dmg-background.png (660x400, 1x) used for the DMG window. Run: swift scripts/generate-dmg-background.swift
import AppKit

let w = 660.0, h = 400.0

func render(scale: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w) * scale, pixelsHigh: Int(h) * scale, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    func col(_ h: UInt32, _ a: CGFloat = 1) -> CGColor { CGColor(srgbRed: CGFloat((h >> 16) & 255) / 255, green: CGFloat((h >> 8) & 255) / 255, blue: CGFloat(h & 255) / 255, alpha: a) }
    ctx.drawLinearGradient(CGGradient(colorsSpace: cs, colors: [col(0xF7F8FF), col(0xE3E7FF), col(0xD3D8FA)] as CFArray, locations: [0, 0.6, 1])!,
                           start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    // arrow between the two icon slots (icons sit at x=170 and x=490, y=205 from the top)
    ctx.setStrokeColor(col(0x4B55C8, 0.75)); ctx.setLineWidth(5); ctx.setLineCap(.round); ctx.setLineJoin(.round)
    let y = h - 205
    ctx.move(to: CGPoint(x: 268, y: y)); ctx.addLine(to: CGPoint(x: 392, y: y)); ctx.strokePath()
    ctx.move(to: CGPoint(x: 372, y: y + 18)); ctx.addLine(to: CGPoint(x: 394, y: y)); ctx.addLine(to: CGPoint(x: 372, y: y - 18)); ctx.strokePath()
    func text(_ s: String, size: CGFloat, weight: NSFont.Weight, color: UInt32, alpha: CGFloat, centerY: CGFloat) {
        let p = NSMutableParagraphStyle(); p.alignment = .center
        let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: NSColor(srgbRed: CGFloat((color >> 16) & 255) / 255, green: CGFloat((color >> 8) & 255) / 255, blue: CGFloat(color & 255) / 255, alpha: alpha), .paragraphStyle: p]
        NSAttributedString(string: s, attributes: a).draw(in: NSRect(x: 0, y: centerY - size, width: w, height: size * 1.6))
    }
    text("Tempora", size: 30, weight: .bold, color: 0x1B2257, alpha: 0.95, centerY: h - 62)
    text("Drag Tempora into Applications  ·  Tempora'yı Uygulamalar'a sürükleyin", size: 13, weight: .medium, color: 0x1B2257, alpha: 0.65, centerY: 92)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// Finder shows DMG backgrounds at pixel size, so a plain 1x PNG matching the window is the reliable choice.
let dir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "scripts")
try render(scale: 1).write(to: dir.appendingPathComponent("dmg-background.png"))
