//
//  AboutAccountView.swift
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

struct AboutAccountView: View {

    enum CompletionType {
        case backup(backupToICloud: Bool), delete(fromBackup: Bool), none
    }

    enum ViewType {
        case delete(existInBackup: Bool), backup(existInBackup: Bool)
    }

    var viewType: ViewType

    let informationType: TopTextBlockView.InformationType
    let titleText: String
    let largeTitleText: String
    let informationText: String
    let privateKey: Data
    var completion: (CompletionType) -> Void
    @State private var removeFromBackup: Bool = false
    @State private var backupToiCloud: Bool = false
    @State private var existInBackup: Bool = false
    @State private var showConfirmDelete: Bool = false

    internal init(viewType: AboutAccountView.ViewType, informationType: TopTextBlockView.InformationType, titleText: String, largeTitleText: String, informationText: String, privateKey: Data, completion: @escaping (AboutAccountView.CompletionType) -> Void) {
        self.viewType = viewType
        self.informationType = informationType
        self.titleText = titleText
        self.largeTitleText = largeTitleText
        self.informationText = informationText
        self.privateKey = privateKey
        self.completion = completion

        switch viewType {
        case .backup(let isInBackup):
            _backupToiCloud = .init(initialValue: isInBackup)
        case .delete(let isInBackup):
            _existInBackup = .init(initialValue: isInBackup)
            break
        }
    }

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

                    }
                    Spacer()
                }
                .padding(EdgeInsets(top: 42, leading: 18, bottom: 16, trailing: 18))
            }
            VStack(spacing: 0) {
                switch viewType {
                case .delete:
                    VStack(alignment: .center, spacing: 24) {
                        HStack {
                            Toggle(isOn: $removeFromBackup) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(R.string.localizable.aboutAccountDeleteRemoveBackupTitle())
                                        .font(.body.weight(.medium))
                                        .foregroundColor(R.color.redText.color)
                                    Text(R.string.localizable.aboutAccountDeleteRemoveBackupSubtitle())
                                        .font(.caption)
                                        .foregroundColor(R.color.secondaryText.color)
                                }
                            }.disabled(!existInBackup)
                        }
                        .padding(16)
                        .background(content: {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(R.color.baseSeparator.color)
                        })
                    }
                    .padding(EdgeInsets(top: 42, leading: 18, bottom: 12, trailing: 18))
                    .opacity(existInBackup ? 1 : 0.4)


                    CButton(title: R.string.localizable.accountsDeleteAccount(), style: .cancel, size: .large, isLoading: false, roundedCorner: false)
                    {
                        showConfirmDelete.toggle()
                    }
                    .padding(EdgeInsets(top: 12, leading: 18, bottom: 16, trailing: 18))
                    Divider()
                case .backup:
                    VStack(alignment: .center, spacing: 24) {
                        HStack {
                            Toggle(isOn: $backupToiCloud) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(R.string.localizable.backupInformationBackupICloudTitle())
                                        .font(.body.weight(.medium))
                                        .foregroundColor(R.color.textBase.color)
                                    Text(R.string.localizable.backupInformationBackupICloudSubtitle())
                                        .font(.caption)
                                        .foregroundColor(R.color.secondaryText.color)
                                }
                            }
                        }
                        .padding(16)
                        .background(content: {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(R.color.baseSeparator.color)
                        })
                    }
                    .padding(EdgeInsets(top: 42, leading: 18, bottom: 12, trailing: 18))
                }

                HStack {
                    CButton(title: closeButtonTitle, style: .secondary, size: .large, isLoading: false, roundedCorner: false)
                    {
                        switch viewType {
                        case .backup:
                            completion(.backup(backupToICloud: backupToiCloud))
                        case .delete:
                            completion(.none)
                        }

                    }
                }
                .padding(EdgeInsets(top: 16, leading: 18, bottom: 24, trailing: 18))
            }
        }
        .confirmationDialog(
            Text(confirmDeleteTitle), isPresented: $showConfirmDelete, actions: {
            Button(R.string.localizable.aboutAccountConfirmYes(), role: .destructive) {
                completion(.delete(fromBackup: removeFromBackup))
            }
            Button(R.string.localizable.commonCancel(), role: .cancel) { }
        })
        .baseBackground()
        .navigationBarColor()
        .edgesIgnoringSafeArea(.bottom)
        .interactiveDismissDisabled()
    }

    private var closeButtonTitle: String {
        switch viewType {
        case .delete:
            return R.string.localizable.commonCancel()
        case .backup:
            return R.string.localizable.commonClose()
        }
    }

    private var confirmDeleteTitle: String {
        if removeFromBackup {
            return R.string.localizable.aboutAccountConfirmFullDeleteTitle()
        }
        return R.string.localizable.aboutAccountConfirmDeleteTitle()
    }
}


struct AboutAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutAccountView(
                viewType: .delete(existInBackup: true),
                informationType: .warning,
                titleText: "Attention",
                largeTitleText: "Remove Account",
                informationText: "Copy the private key and save it in the password manager or in another safe place",
                privateKey: Data(),
                completion: { _ in }
            )
            .environmentObject(AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(), accountService: AccountServiceImpl(storage: MockAccountStorage()), backupStorage: BackupStorageMock())))
        }
    }
}
