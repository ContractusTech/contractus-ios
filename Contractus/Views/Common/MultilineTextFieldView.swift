//
//  MultilineTextFieldView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.10.2022.
//

import SwiftUI
import Introspect

fileprivate enum Constants {
    static let contactIcon = Image(systemName: "person.fill.badge.plus")

    static let seeIcon = Image(systemName: "eye.fill")
    static let cancelSeeIcon = Image(systemName: "eye.slash.fill")
}

struct MultilineTextFieldView: View {

    private enum Field: Int, CaseIterable {
        case privateKey
    }

    let placeholder: String
    @Binding var value: String

    @FocusState var isInputActive: Bool

    var body: some View {
        

        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $value)
                .focused($isInputActive)
                .setBackground(color: R.color.thirdBackground.color)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(R.string.localizable.commonDone()) {
                            isInputActive = false
                        }.font(.body.weight(.medium))
                    }


                }
                .padding(.bottom, 24)
            HStack {
                Button {

                } label: {
                    Constants.cancelSeeIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(R.color.textBase.color)
                }
                Spacer()

                Button {
                    value = UIPasteboard.general.string ?? ""
                } label: {
                    Text(R.string.localizable.commonPaste())
                        .foregroundColor(R.color.textBase.color)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }

        }
        .frame(height: 130)
        .padding()
        .background(R.color.thirdBackground.color)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(R.color.textFieldBorder.color, lineWidth: 1)
        )
    }
}

struct MultilineTextFieldView_Previews: PreviewProvider {
    static var previews: some View {

        MultilineTextFieldView(placeholder: "Enter private key", value: Binding(get: { "" }, set: { _, _ in }))
            .padding()
    }
}
