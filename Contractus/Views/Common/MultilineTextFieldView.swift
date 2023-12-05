//
//  MultilineTextFieldView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.10.2022.
//

import SwiftUI

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
    @State var isSecured: Bool = false

    var displayValue: Binding<String> {
        .init { isSecured ? ContentMask.mask(from: value, visibleCount: 4, maskCount: 0) : value}
        set: { (newValue, transaction) in
            if isSecured {
                value = value
            } else {
                value = newValue
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: displayValue)
                .disabled(isSecured)
                .font(.system(size: 14, design: .monospaced))
                .focused($isInputActive)
                .setBackground(color: isSecured ? R.color.mainBackground.color : R.color.textFieldBackground.color)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(R.string.localizable.commonDone()) {
                            isInputActive = false
                        }
                        .font(.body.weight(.medium))
                    }
                }
                .padding(.bottom, 24)
            HStack {
                Button {
                    isSecured.toggle()
                } label: {
                    visibleIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(R.color.textBase.color)
                }
                Spacer()

                Button {
                    let pasteValue = UIPasteboard.general.string ?? ""
                    value = pasteValue
                    isSecured = !pasteValue.isEmpty
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
        .background(isSecured ? R.color.mainBackground.color : R.color.textFieldBackground.color)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(R.color.textFieldBorder.color, lineWidth: 1)
        )
    }

    var visibleIcon: Image {
        if self.isSecured {
            Constants.seeIcon
        } else {
            Constants.cancelSeeIcon
        }
    }
}

struct MultilineTextFieldView_Previews: PreviewProvider {
    static var previews: some View {

        MultilineTextFieldView(placeholder: "Enter private key", value: Binding(get: { "" }, set: { _, _ in }))
            .padding()
    }
}
