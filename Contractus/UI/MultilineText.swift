import SwiftUI

 struct MultilineText: UIViewRepresentable {
    let text: String?
    let font: UIFont?
    let textAlignment: NSTextAlignment?
    let textColor: UIColor?
    let preferredMaxLayoutWidth: CGFloat
    
    @Environment(\.lineLimit) private var lineLimit: Int?
    
    init(
        _ text: String?,
        font: UIFont? = nil,
        textAlignment: NSTextAlignment? = nil,
        textColor: UIColor? = nil,
        preferredMaxLayoutWidth: CGFloat
    ) {
        self.text = text
        self.font = font
        self.textAlignment = textAlignment
        self.textColor = textColor
        self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    }
    
    func makeUIView(context: UIViewRepresentableContext<MultilineText>) -> UILabel {
        let label = UILabel(frame: .zero)
        
        label.numberOfLines = lineLimit ?? 0
        if let textColor = textColor {
            label.textColor = textColor
        }
        if let font = font {
            label.font = font
        }
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.allowsDefaultTighteningForTruncation = true
        label.minimumScaleFactor = 0.8
        
        updateUIView(label, context: context)
        return label
    }
    
    func updateUIView(_ label: UILabel, context: UIViewRepresentableContext<MultilineText>) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment ?? .natural
        label.text = text
        label.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    }
}
