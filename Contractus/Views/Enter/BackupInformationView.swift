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
                Constants.backupImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140, alignment: .center)
                    .padding()

                Text(R.string.localizable.backupInformationTitle())
                    .font(.largeTitle)
                Text(R.string.localizable.backupInformationSubtitle()).font(.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                HStack {
                    Text(KeyFormatter.format(from: privateKey.toHexString()))
                        .font(.title3)
                    Spacer()
                    Button {
                        viewModel.trigger(.copyPrivateKey)
                        withAnimation(.easeInOut) {
                            copiedNotification = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation(.easeInOut) {
                                    copiedNotification = false
                                }
                            }
                        }
                    } label: {
                        Constants.copyImage
                            .foregroundColor(R.color.textBase.color)
                    }
                }
                .padding()
                .background(R.color.thirdBackground.color)
                .cornerRadius(10)

                HStack {
                    Constants.successCopyImage
                    Text(R.string.localizable.createWalletButtonCopied())
                }
                .opacity(copiedNotification ? 1 : 0)
                Spacer()
            }

            Spacer()
            Text(R.string.localizable.backupInformationTooltip()).font(.caption)
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
