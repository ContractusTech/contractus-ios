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

    enum Mode {
        case view, edit
    }

    @State var content: String = ""
    @State var mode: Mode = .view

    let allowEdit: Bool
    var onUpdateContent: (String) -> Void
    var onDismiss: () -> Void

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
                        Text("Enter contract details")
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
                        Text("Empty contract details")
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
                    switch mode {
                    case .edit:
                        Button {
                            onUpdateContent(content)
                        } label: {
                            Text(R.string.localizable.commonSave())
                                .fontWeight(.bold)
                        }
                    case .view:
                        EmptyView()
                    }
                }


                ToolbarItem(placement: .principal) {
                    if allowEdit {
                        Picker("Mode", selection: $mode) {
                            Text("View").tag(Mode.view)
                            Text("Edit").tag(Mode.edit)
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
                            onDismiss() // TODO: - Добавить alert, "Вы уверены..."
                        case .view:
                            onDismiss()
                        }

                    } label: {
                        Constants.closeImage
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(R.color.textBase.color)

                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .onDisappear {
            onDismiss()
        }
    }
}

struct TextViewerView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(content: "", allowEdit: true) { _ in
            
        } onDismiss: {
            
        }
    }
}
