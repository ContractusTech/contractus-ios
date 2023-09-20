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
}


struct TextEditorView: View {

    enum AlertType: Identifiable {
        var id: String {
            return "\(self)"
        }
        case error(String), needConfirmForceUpdate
    }
    
    enum Mode {
        case view, edit
    }

    enum ActionResult {
        case close, success(DealMetadata)
    }

    @Environment(\.presentationMode) var presentationMode

    let allowEdit: Bool
    @StateObject var viewModel: AnyViewModel<TextEditorState, TextEditorInput>
    var action: (ActionResult) -> Void

    @State var content: String = ""
    @State var mode: Mode = .view
    @State private var alertType: AlertType?
    @FocusState var isInputActive: Bool

    var body: some View {
        NavigationView {
            HStack {
                ZStack(alignment: .topLeading) {

                    switch mode {
                    case .edit:
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $content)
                                .disabled(false)
                                .setBackground(color: R.color.textFieldBackground.color)
                                .cornerRadius(20)
                                .padding(6)
                                .focused($isInputActive)
                                .onTapGesture {}
                                .onLongPressGesture(
                                    pressing: { isPressed in
                                        if isPressed {
                                            self.endEditing()
                                        }
                                    }) {}
                                .onAppear {
                                    isInputActive = true
                                }

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
                        TextEditor(text: $content)
                            .disabled(true)
                            .setBackground(color: R.color.mainBackground.color)
                            .cornerRadius(12)
                            .padding(6)
                        if content.isEmpty {
                            Text(R.string.localizable.dealTextEditorViewPlaceholder())
                                .padding(EdgeInsets(top: 14, leading: 12, bottom: 0, trailing: 5))
                                .foregroundColor(R.color.secondaryText.color)
                        }

                        Spacer()

                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .inset(by: 0.5)
                        .stroke(R.color.textFieldBorder.color, lineWidth: mode != .view ? 1 : 0))
            }
            .padding()
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
                            action(.close) // TODO: - Добавить alert, "Вы уверены..."
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
            case .error(let message):
                return Alert(
                    title: Text(R.string.localizable.commonError()),
                    message: Text(message), dismissButton: Alert.Button.default(Text(R.string.localizable.commonOk()), action: {
                        viewModel.trigger(.dismissError)
                    }))
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
}

struct TextViewerView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(allowEdit: true, viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(dealId: Mock.deal.id, content: Mock.deal.meta ?? .init(files: []), contentType: .metadata, secretKey: Mock.account.privateKey, dealService: nil))) { result in

        }
    }
}
