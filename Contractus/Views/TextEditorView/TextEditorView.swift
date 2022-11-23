//
//  TextEditorView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 19.08.2022.
//

import SwiftUI
import ContractusAPI
//import QRCode
import Introspect

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
}


struct TextEditorView: View {

    enum AlertType {
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

    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {

                switch mode {
                case .edit:

                    if #available(iOS 16.0, *) {
                        TextEditor(text: $content)
                            .scrollContentBackground(.hidden)
                            .background(R.color.mainBackground.color)
                            .disabled(false)
                            .introspectTextView { tv in
                                tv.becomeFirstResponder()
                            }
                            .onTapGesture {}
                            .onLongPressGesture(
                                pressing: { isPressed in if isPressed { self.endEditing() } },
                                perform: {}
                            )
                    } else {
                        TextEditor(text: $content)
                            .disabled(false)
                            .textEditorBackground({
                                R.color.mainBackground.color
                            })
                            .introspectTextView { tv in
                                tv.becomeFirstResponder()
                            }
                            .onTapGesture {}
                            .onLongPressGesture(
                                pressing: { isPressed in if isPressed { self.endEditing() } },
                                perform: {}
                            )
                    }

                    if content.isEmpty {
                        Text(R.string.localizable.dealTextEditorEditorPlaceholder())
                            .padding(EdgeInsets(top: 8, leading: 5, bottom: 0, trailing: 5))
                            .foregroundColor(R.color.secondaryText.color)
                    }

                    Spacer()
                case .view:
                    if #available(iOS 16.0, *) {
                        TextEditor(text: $content)
                            .scrollContentBackground(.hidden)
                            .background(R.color.mainBackground.color)
                            .disabled(true)
                    } else {
                        TextEditor(text: $content)
                            .disabled(true)
                            .textEditorBackground({
                                R.color.mainBackground.color
                            })
                    }

                    if content.isEmpty {
                        Text(R.string.localizable.dealTextEditorViewPlaceholder())
                            .padding(EdgeInsets(top: 8, leading: 5, bottom: 0, trailing: 5))
                            .foregroundColor(R.color.secondaryText.color)
                    }

                    Spacer()

                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(R.string.localizable.dealViewContractText())
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarColor()
            .baseBackground()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.state.state == .updating {
                        ProgressView()
                    } else {
                        switch mode {
                        case .edit:
                            Button {
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
                    message: Text(message))
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
            case .error(_):
                break
            case .success:
                presentationMode.wrappedValue.dismiss()
            }
        })
        .onAppear {
            viewModel.trigger(.decrypt)
        }

    }
}

extension TextEditorView.AlertType: Identifiable {
    var id: String {
        switch self {
        case .error:
            return "error"
        case .needConfirmForceUpdate:
            return "needConfirmForceUpdate"
        }
    }
}

struct TextViewerView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(allowEdit: true, viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(dealId: Mock.deal.id, content: Mock.deal.meta ?? .init(files: []), contentType: .metadata, secretKey: Mock.account.privateKey, dealService: nil))) { result in

        }
    }
}
