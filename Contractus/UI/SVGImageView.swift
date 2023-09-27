import SwiftUI
import SVGKit

let cache = NSCache<NSString, SVGKImage>()

public struct SVGImageView: UIViewRepresentable {
    public let url: URL
    public let size: CGSize

    public init(url: URL, size: CGSize) {
        self.url = url
        self.size = size
    }

    public func makeUIView(context: Context) -> SVGKFastImageView {
        let imageView: SVGKFastImageView = SVGKFastImageView(svgkImage: SVGKImage())
        imageView.backgroundColor = R.color.fourthBackground()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    public func updateUIView(_ imageView: SVGKFastImageView, context: Context) {
        if let image = cache.object(forKey: url.absoluteString as NSString) {
            imageView.image = image
            imageView.backgroundColor = .clear
            imageView.image.size = size
        } else {
            let url = self.url
            DispatchQueue.global(qos: .userInitiated).async {
                if let svgImage = SVGKImage(contentsOf: url) {
                    cache.setObject(svgImage, forKey: url.absoluteString as NSString)
                    DispatchQueue.main.async {
                        guard url == self.url else { return }
                        imageView.image = svgImage
                        imageView.backgroundColor = .clear
                        imageView.image.size = size
                    }
                }
            }
        }
    }
}
