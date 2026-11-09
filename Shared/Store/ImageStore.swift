import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Stores user images on disk (downsampled) inside the App Group container.
/// Widgets have a tight memory budget, so nothing larger than `maxPixel` is kept.
enum ImageStore {
    enum Kind { case background, icon }

    static func importImage(from url: URL, kind: Kind) throws -> String {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw CocoaError(.fileReadCorruptFile) }
        return try store(source: source, kind: kind)
    }

    static func importImage(data: Data, kind: Kind) throws -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { throw CocoaError(.fileReadCorruptFile) }
        return try store(source: source, kind: kind)
    }

    private static func store(source: CGImageSource, kind: Kind) throws -> String {
        let maxPixel = kind == .background ? 1600 : 256
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let isIcon = kind == .icon
        let name = "\(isIcon ? "icon" : "bg")-\(UUID().uuidString).\(isIcon ? "png" : "jpg")"
        let url = AppGroup.imagesDirectory.appending(path: name)
        let type = (isIcon ? UTType.png : UTType.jpeg).identifier as CFString
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        return name
    }

    static func image(named file: String) -> NSImage? {
        NSImage(contentsOf: AppGroup.imagesDirectory.appending(path: file))
    }

    /// Deletes images that no countdown references any more.
    static func removeUnused(keeping used: Set<String>) {
        let dir = AppGroup.imagesDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path()) else { return }
        for file in files where !used.contains(file) {
            try? FileManager.default.removeItem(at: dir.appending(path: file))
        }
    }
}
