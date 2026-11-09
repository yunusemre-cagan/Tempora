import AppKit
import SwiftUI

/// Template image for the menu bar: the Kalan "K" with its ticking dot.
enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()
            let k = NSBezierPath()
            k.lineWidth = 2.3
            k.lineCapStyle = .round
            k.lineJoinStyle = .round
            k.move(to: NSPoint(x: 4.6, y: 3.2)); k.line(to: NSPoint(x: 4.6, y: 14.8))   // stem
            k.move(to: NSPoint(x: 5.2, y: 9.3)); k.line(to: NSPoint(x: 11.4, y: 14.6))  // upper arm
            k.move(to: NSPoint(x: 7.0, y: 8.4)); k.line(to: NSPoint(x: 11.6, y: 3.4))   // lower leg
            k.stroke()
            NSBezierPath(ovalIn: NSRect(x: 12.9, y: 6.4, width: 3.2, height: 3.2)).fill() // the tick
            return true
        }
        image.isTemplate = true
        return image
    }()
}
