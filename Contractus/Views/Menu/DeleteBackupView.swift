//
//  DeleteBackupView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.03.2023.
//


import SwiftUI
import SolanaSwift

fileprivate enum Constants {
    static let copyImage = Image(systemName: "doc.on.doc")
    static let successCopyImage = Image(systemName: "checkmark")
    static let backupImage = Image(systemName: "exclamationmark.triangle")
}

struct DeleteBackupView: View {

    enum CompletioniewType {
        case copyPrivateKey, delete, cancel
    }

    enum DeleteBackupViewType {
        case delete, backup
    }

//    @EnvironmentObject var viewModel: AnyViewModel<EnterState, EnterInput>

    var viewType: DeleteBackupViewType = .backup

    let informationType: TopTextBlockView.InformationType
    let titleText: String
    let largeTitleText: String
    let informationText: String
    let privateKey: Data

    var completion: (CompletioniewType) -> Void

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
                        completion(.copyPrivateKey)
                    }
                    Spacer()
                }
                .padding(EdgeInsets(top: 12, leading: 18, bottom: 16, trailing: 18))
            }
            VStack(spacing: 0) {
                if viewType == .delete {
                    Text("You cannot recover access to the account\nwithout the private key.")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                    
                    CButton(title: "Delete account", style: .cancel, size: .large, isLoading: false, roundedCorner: true)
                    {
                        completion(.delete)
                    }
                    .padding(EdgeInsets(top: 12, leading: 18, bottom: 16, trailing: 18))
                    Divider()
                }
                HStack {

                    CButton(title: R.string.localizable.commonCancel(), style: .secondary, size: .large, isLoading: false, roundedCorner: true)
                    {
                        completion(.cancel)
                    }
                }
                .padding(EdgeInsets(top: 16, leading: 18, bottom: 24, trailing: 18))
            }
        }
//        .onAppear {
//            viewModel.trigger(.createIfNeeded)
//        }
        .navigationBarTitleDisplayMode(.inline)
        .baseBackground()
        .navigationBarColor()
        .edgesIgnoringSafeArea(.bottom)
    }
}


struct DeleteBackupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeleteBackupView(
                informationType: .warning,
                titleText: "Attention",
                largeTitleText: "Remove Account",
                informationText: "Copy the private key and save it in the password manager or in another safe place",
                privateKey: Data(),
                completion: { _ in }
            )
            .environmentObject(AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(), accountService: AccountServiceImpl(storage: MockAccountStorage()))))
        }
    }
}