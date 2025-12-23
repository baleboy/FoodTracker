//
//  ImageHelpers.swift
//  FoodTracker
//

import UIKit
import ImageIO

enum ImageHelpers {
    static func resizeAndCompress(
        _ imageData: Data,
        maxDimension: CGFloat = 1024,
        quality: CGFloat = 0.8
    ) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }

        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage.jpegData(compressionQuality: quality)
    }

    static func extractCaptureDate(from imageData: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String
        else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }
}
