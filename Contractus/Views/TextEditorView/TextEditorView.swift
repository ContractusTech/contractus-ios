//
//  TextEditorView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 19.08.2022.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
    static let backwardImage = Image(systemName: "arrow.uturn.backward")
    static let forwardImage = Image(systemName: "arrow.uturn.forward")
}

struct TextEditorView: View {

    enum AlertType: Identifiable {
        var id: String {
            return "\(self)"
        }
        case error(String), needConfirmForceUpdate, confirmClose, needHolderMode
    }
    
    enum Mode {
        case view, edit
    }

    enum ActionResult {
        case close, success(DealMetadata)
    }

    @Environment(\.presentationMode) var presentationMode

    let allowEdit: Bool
    @State var mode: Mode
    @StateObject var viewModel: AnyViewModel<TextEditorState, TextEditorInput>
    var action: (ActionResult) -> Void

    @State var content: String = ""
    @State private var alertType: AlertType?
    @State private var undoManager: UndoManager?
    @FocusState var isInputActive: Bool

    var body: some View {
        NavigationView {
            HStack {
                ZStack(alignment: .topLeading) {
                    switch mode {
                    case .edit:
                        ZStack(alignment: .topLeading) {
                            UndoTextView(content: $content, undoManager: $undoManager)
                                .disabled(false)
                                .setBackground(color: R.color.textFieldBackground.color)
                                .padding(6)
                                .focused($isInputActive)
                                .onAppear {
                                    isInputActive = true
                                }
                                .padding(.bottom, 42)

                            if content.isEmpty {
                                Text(R.string.localizable.dealTextEditorEditorPlaceholder())
                                    .padding(EdgeInsets(top: 14, leading: 12, bottom: 0, trailing: 5))
                                    .foregroundColor(R.color.secondaryText.color)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(R.color.textFieldBackground.color)
                        .cornerRadius(20)
                        Spacer()
                    case .view:
                        ScrollView {
                            HStack(spacing: 0) {
                                if content.isEmpty {
                                    Text(R.string.localizable.dealTextEditorViewPlaceholder())
                                        .foregroundColor(R.color.secondaryText.color)
                                        .font(.body)
                                } else {
                                    Text(content)
                                }
                                Spacer()
                            }
                            .setBackground(color: R.color.mainBackground.color)
                            .padding(EdgeInsets(top: 14, leading: 11, bottom: 0, trailing: 5))
                        }
                        .padding(.bottom, 6)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .inset(by: 0.5)
                        .stroke(R.color.textFieldBorder.color, lineWidth: mode != .view ? 1 : 0))
                .overlay(alignment: .bottom) {
                    if mode == .edit {
                        controlsView()
                    } else {
                        EmptyView()
                    }
                }
            }
            .padding(8)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(R.string.localizable.dealViewContractText())
            .navigationViewStyle(StackNavigationViewStyle())
            .baseBackground()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.state.state == .updating {
                        ProgressView()
                    } else {
                        switch mode {
                        case .edit:
                            Button {
                                switch viewModel.state.contentType {
                                case .metadata:
                                    EventService.shared.send(event: DefaultAnalyticsEvent.dealDescriptionSaveTap)
                                case .result:
                                    EventService.shared.send(event: DefaultAnalyticsEvent.dealResultSaveTap)
                                }
                                viewModel.trigger(.update(content, false))
                            } label: {
                                Text(R.string.localizable.commonSave())
                                    .fontWeight(.bold)
                            }
                        case .view:
                            EmptyView()
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    if allowEdit {
                        Picker("", selection: $mode) {
                            Text(R.string.localizable.dealTextEditorModeViewer()).tag(Mode.view)
                            Text(R.string.localizable.dealTextEditorModeEditor()).tag(Mode.edit)
                        }
                        .frame(width: 200)
                        .pickerStyle(SegmentedPickerStyle())
                    } else {
                        EmptyView()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        switch mode {
                        case .edit:
                            if (undoManager?.canRedo ?? false || undoManager?.canUndo ?? false) {
                                alertType = .confirmClose
                            } else {
                                action(.close)
                            }
                        case .view:
                            action(.close)
                        }

                    } label: {
                        Constants.closeImage
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(R.color.textBase.color)

                    }.disabled(viewModel.state.state == .updating)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .alert(item: $alertType, content: { type in
            switch type {
            case .confirmClose:
                return Alert(
                    title: Text(R.string.localizable.dealConfirmCloseTitle()),
                    message:  Text(R.string.localizable.dealConfirmCloseMessage()),
                    primaryButton: Alert.Button.default(Text(R.string.localizable.commonClose())) {
                        action(.close)
                    },
                    secondaryButton: Alert.Button.cancel {

                    })
            case .error(let message):
                return Alert(
                    title: Text(R.string.localizable.commonError()),
                    message: Text(message), dismissButton: Alert.Button.default(Text(R.string.localizable.commonOk()), action: {
                        viewModel.trigger(.dismissError)
                    }))
            case .needHolderMode:
                return Alert(
                    title: Text(R.string.localizable.aiGenAlertTitle()),
                    message: Text(R.string.localizable.aiGenAlertMessage()),
                    dismissButton: Alert.Button.default(Text(R.string.localizable.commonOk())))
            case .needConfirmForceUpdate:
                return Alert(
                    title: Text(R.string.localizable.commonAttention()),
                    message:  Text(R.string.localizable.dealTextEditorMessageForceUpdate()),
                    primaryButton: Alert.Button.destructive(Text(R.string.localizable.dealTextEditorForceUpdate())) {
                        viewModel.trigger(.update(content, true))
                    },
                    secondaryButton: Alert.Button.cancel {

                    })
            }

        })

        .onChange(of: viewModel.state.state, perform: { newState in
            switch newState {
            case .decrypted(let content):
                self.content = content
            case .decrypting:
                break // TODO: - Добавить индикатор, что идет расшифровка
            case .needConfirmForce:
                alertType = .needConfirmForceUpdate
            case .none:
                break
            case .updating:
                break
            case .success:
                action(.success(viewModel.state.content))
                presentationMode.wrappedValue.dismiss()
            }
        })
        .onChange(of: viewModel.state.errorState) { errorState in
            switch errorState {
            case .error(let message):
                alertType = .error(message)
            case .none:
                alertType = nil
            }
        }
        .onAppear {
            viewModel.trigger(.decrypt)
        }

    }

    @ViewBuilder
    func controlsView() -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(R.color.textFieldBorder.color)
            HStack(spacing: 12) {
                Button {
                    undoManager?.undo()
                } label: {
                    Constants.backwardImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .padding(10)
                        .foregroundColor(R.color.accentColor.color)
                }
                .disabled((undoManager?.canUndo ?? false) ? false : true)
                .opacity((undoManager?.canUndo ?? false) ? 1.0 : 0.3)

                Button {
                    undoManager?.redo()
                } label: {
                    Constants.forwardImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .padding(10)
                        .foregroundColor(R.color.accentColor.color)
                }
                .disabled((undoManager?.canRedo ?? false) ? false : true)
                .opacity((undoManager?.canRedo ?? false) ? 1.0 : 0.3)
                Spacer()
                if viewModel.state.tier == .holder {
                    NavigationLink {
                        TextGenView { genText in
                            self.content = genText
                        }
                    } label: {
                        Text(R.string.localizable.aiGenTitle())
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(R.color.buttonBackgroundPrimary.color)
                            .foregroundColor(R.color.buttonTextPrimary.color)
                            .cornerRadius(16)
                    }
                } else {
                    Button {
                        alertType = .needHolderMode
                    } label: {
                        Text(R.string.localizable.aiGenTitle())
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(R.color.buttonBackgroundPrimary.color)
                            .foregroundColor(R.color.buttonTextPrimary.color)
                            .cornerRadius(16)
                    }

                }
            }
            .padding(EdgeInsets(top: 0, leading: 6, bottom: 2, trailing: 6))
        }
    }
}

struct TextViewerView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(
            allowEdit: true,
            mode: .edit,
            viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(dealId: Mock.deal.id, tier: .basic, content: Mock.deal.meta ?? .init(files: []), contentType: .metadata, secretKey: Mock.account.privateKey, dealService: nil))
        ) { result in

        }

        TextEditorView(
            allowEdit: true,
            mode: .edit,
            viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(dealId: Mock.deal.id, tier: .holder, content: Mock.deal.meta ?? .init(files: []), contentType: .metadata, secretKey: Mock.account.privateKey, dealService: nil))
        ) { result in

        }
    }
}
