import AppKit
import SwiftUI

/// Template image for the menu bar: a small hourglass.
enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            // caps
            let caps = NSBezierPath()
            caps.lineWidth = 1.6
            caps.lineCapStyle = .round
            caps.move(to: NSPoint(x: 3.8, y: 15.6)); caps.line(to: NSPoint(x: 14.2, y: 15.6))
            caps.move(to: NSPoint(x: 3.8, y: 2.4)); caps.line(to: NSPoint(x: 14.2, y: 2.4))
            caps.stroke()

            // glass
            let glass = NSBezierPath()
            glass.lineWidth = 1.1
            glass.lineJoinStyle = .round
            glass.move(to: NSPoint(x: 5.2, y: 14.4))
            glass.line(to: NSPoint(x: 12.8, y: 14.4))
            glass.curve(to: NSPoint(x: 9.9, y: 9), controlPoint1: NSPoint(x: 12.8, y: 11.8), controlPoint2: NSPoint(x: 10.2, y: 10.2))
            glass.curve(to: NSPoint(x: 12.8, y: 3.6), controlPoint1: NSPoint(x: 10.2, y: 7.8), controlPoint2: NSPoint(x: 12.8, y: 6.2))
            glass.line(to: NSPoint(x: 5.2, y: 3.6))
            glass.curve(to: NSPoint(x: 8.1, y: 9), controlPoint1: NSPoint(x: 5.2, y: 6.2), controlPoint2: NSPoint(x: 7.8, y: 7.8))
            glass.curve(to: NSPoint(x: 5.2, y: 14.4), controlPoint1: NSPoint(x: 7.8, y: 10.2), controlPoint2: NSPoint(x: 5.2, y: 11.8))
            glass.close()
            glass.stroke()

            // sand
            let top = NSBezierPath()
            top.move(to: NSPoint(x: 7.3, y: 12.6)); top.line(to: NSPoint(x: 10.7, y: 12.6)); top.line(to: NSPoint(x: 9, y: 10.4)); top.close()
            top.fill()
            let bottom = NSBezierPath()
            bottom.move(to: NSPoint(x: 6.9, y: 4.8)); bottom.line(to: NSPoint(x: 11.1, y: 4.8)); bottom.line(to: NSPoint(x: 9, y: 6.9)); bottom.close()
            bottom.fill()
            return true
        }
        image.isTemplate = true
        return image
    }()
}
