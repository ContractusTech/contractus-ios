import SwiftUI

struct UnlockHolderButtonView: View {
    var tapAction: (() -> Void)?
    var body: some View {
        Button {
            tapAction?()
        } label: {
            ZStack {
                R.image.holderBackground.image
                    .resizable()
                    .scaledToFit()
                HStack(spacing: 0) {
                    R.image.holderLogo.image
                        .padding(16)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(R.string.localizable.unlockHolderMainButtonTitle())
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                        Text(R.string.localizable.unlockHolderMainButtonSubtitle())
                            .font(.footnote.weight(.regular))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
            }
            .background(R.color.blue.color)
            .cornerRadius(17)
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(WideButton())
    }
}

struct UnlockHolderButtonView_Previews: PreviewProvider {
    static var previews: some View {
        UnlockHolderButtonView()
    }
}
