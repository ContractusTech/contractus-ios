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
                .padding(EdgeInsets(top: 42, leading: 18, bottom: 16, trailing: 18))
            }
            VStack(spacing: 0) {
                if viewType == .delete {
                    Text(R.string.localizable.accountsDeleteWarning())
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundColor(R.color.redText.color)
                    
                    CButton(title: R.string.localizable.accountsDeleteAccount(), style: .cancel, size: .large, isLoading: false, roundedCorner: false)
                    {
                        completion(.delete)
                    }
                    .padding(EdgeInsets(top: 12, leading: 18, bottom: 16, trailing: 18))
                    Divider()
                }
                HStack {
                    CButton(title: R.string.localizable.commonCancel(), style: .secondary, size: .large, isLoading: false, roundedCorner: false)
                    {
                        completion(.cancel)
                    }
                }
                .padding(EdgeInsets(top: 16, leading: 18, bottom: 24, trailing: 18))
            }
        }
        .baseBackground()
        .navigationBarColor()
        .edgesIgnoringSafeArea(.bottom)
    }
}


struct DeleteBackupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeleteBackupView(
                viewType: .delete,
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
