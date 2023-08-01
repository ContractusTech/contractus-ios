import SwiftUI

fileprivate enum Constants {
    static let cardImage = Image(systemName: "creditcard")
    static let depositImage = Image(systemName: "arrow.down.to.line")
    static let loanImage = Image(systemName: "percent")
}

struct TopUpView: View {
    enum TopUpType {
        case crypto
        case load
        case fiat
    }
    
    var action: (TopUpType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(R.string.localizable.commonTopUp())
                    .font(.title2)
            }
            .padding(.bottom, 6)
            .padding(.top, 6)
            itemView(image: Constants.depositImage, title: R.string.localizable.topupTitleCrypto(), description: R.string.localizable.topupSubtitleCrypto(), disabled: false) {
                action(.crypto)
            }

            itemView(image: Constants.cardImage, title: R.string.localizable.topupTitleCards(), description: R.string.localizable.topupSubtitleCards(), disabled: true) {
                action(.fiat)
            }

            itemView(image: Constants.loanImage, title: R.string.localizable.topupTitleLoad(), description: R.string.localizable.topupSubtitleLoad(), disabled: true) {
                action(.load)
            }
            Spacer()
        }
        .padding(20)
    }

    @ViewBuilder
    func itemView(image: Image, title: String, description: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(alignment: .center) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .padding(4)

                VStack(alignment: .leading, spacing: 6){
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(R.color.textBase.color)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(R.color.secondaryText.color)
                }
                Spacer()

            }
            .padding()
            .background(content: {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(R.color.baseSeparator.color, lineWidth: 1)
            })
            .opacity(disabled ? 0.6 : 1.0)
        }
        .disabled(disabled)

    }
}

struct TopUpView_Previews: PreviewProvider {
    static var previews: some View {
        TopUpView { _ in

        }
    }
}
