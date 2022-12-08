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

    let informationType: TopTextBlockView.InformationType
    let titleText: String
    let largeTitleText: String
    let informationText: String
    let privateKey: Data

    var completion: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    TopTextBlockView(
                        informationType: informationType,
                        headerText: titleText,
                        titleText: largeTitleText,
                        subTitleText: informationText)

                    CopyContentView(content: privateKey.toBase58(), contentType: .privateKey) { _ in
                        viewModel.trigger(.copyForBackup)
                    }
                    Spacer()
                }
                .padding(UIConstants.contentInset)
            }
            VStack {
                Text(R.string.localizable.backupInformationTooltip())
                    .multilineTextAlignment(.center)
                    .font(.body.weight(.medium))
                    .foregroundColor(R.color.yellow.color)
                    .padding(10)

                HStack {

                    CButton(title: R.string.localizable.backupInformationButtonContinue(), style: .secondary, size: .large, isLoading: false)
                    {
                        viewModel.trigger(.saveAccount)
                        completion()
                    }
                }
                .padding(UIConstants.contentInset)
            }
        }
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
            BackupInformationView(
                informationType: .warning,
                titleText: "import success",
                largeTitleText: "Your safety",
                informationText: "",
                privateKey: Data(),
                completion: {}).environmentObject(AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(), accountService: AccountServiceImpl(storage: MockAccountStorage()))))
        }
        .preferredColorScheme(.dark)

    }
}
