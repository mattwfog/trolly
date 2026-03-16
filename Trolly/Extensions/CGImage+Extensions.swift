import CoreGraphics
import CoreImage

extension CGImage {
    var ciImage: CIImage {
        CIImage(cgImage: self)
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }
}
