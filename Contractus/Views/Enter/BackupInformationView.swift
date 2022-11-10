//
//  BackupInformationView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 31.07.2022.
//

import SwiftUI
import SolanaSwift

fileprivate enum Constants {
    static let copyImage = Image(systemName: "doc.on.doc")
    static let successCopyImage = Image(systemName: "checkmark")
    static let backupImage = Image(systemName: "exclamationmark.triangle")
}

struct BackupInformationView: View {

    @EnvironmentObject var rootViewModel: AnyViewModel<RootState, RootInput>
    @EnvironmentObject var viewModel: AnyViewModel<EnterState, EnterInput>
    let privateKey: Data
    var completion: () -> Void
    @State var copiedNotification: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center, spacing: 24) {
                VStack(spacing: 8) {
                    Text("New wallet")
                        .font(.footnote.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundColor(R.color.secondaryText.color)

                    Text(R.string.localizable.backupInformationTitle())
                        .font(.largeTitle.weight(.heavy))
                    Text(R.string.localizable.backupInformationSubtitle())
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))

                CopyContentView(content: privateKey.toHexString(), contentType: .privateKey) { _ in
                    viewModel.trigger(.copyPrivateKey)
                    withAnimation(.easeInOut) {
                        copiedNotification = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation(.easeInOut) {
                                copiedNotification = false
                            }
                        }
                    }
                }
                HStack {
                    Constants.successCopyImage
                    Text(R.string.localizable.createWalletButtonCopied())
                }
                .opacity(copiedNotification ? 1 : 0)
                Spacer()
            }

            Spacer()
            Text(R.string.localizable.backupInformationTooltip())
                .font(.body.weight(.medium))
                .foregroundColor(R.color.yellow.color)
            HStack {
                Button {
                    viewModel.trigger(.saveAccount)
                    completion()
                } label: {
                    HStack {
                        Spacer()
                        Text(R.string.localizable.backupInformationButtonContinue())
                        Spacer()
                    }
                }.buttonStyle(PrimaryLargeButton())
            }
            .padding(.bottom, 24)
        }
        .padding()

        .onAppear {
            viewModel.trigger(.createIfNeeded)
        }
        .navigationBarTitleDisplayMode(.inline)
        .baseBackground()
        .navigationBarColor()
        .edgesIgnoringSafeArea(.bottom)


    }
}


struct BackupInformationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BackupInformationView(privateKey: Data(), completion: {}).environmentObject(AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(), accountService: AccountServiceImpl(storage: MockAccountStorage()))))
        }
        .preferredColorScheme(.dark)

    }
}
