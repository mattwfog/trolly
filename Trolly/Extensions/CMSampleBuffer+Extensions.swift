import CoreMedia
import CoreVideo

extension CMSampleBuffer {
    var presentationSeconds: TimeInterval? {
        let time = CMSampleBufferGetPresentationTimeStamp(self)
        guard time.isValid else { return nil }
        return CMTimeGetSeconds(time)
    }

    var pixelBuffer: CVPixelBuffer? {
        CMSampleBufferGetImageBuffer(self)
    }
}
