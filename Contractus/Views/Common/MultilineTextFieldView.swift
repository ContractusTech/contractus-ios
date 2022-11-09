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

    let placeholder: String
    @Binding var value: String

    var body: some View {

        ZStack(alignment: .bottomTrailing) {

            if #available(iOS 16.0, *) {
                TextEditor(text: $value)
                    .scrollContentBackground(.hidden)
                    .background(R.color.thirdBackground.color)
            } else {
                TextEditor(text: $value).textEditorBackground {
                    R.color.thirdBackground.color
                }
            }

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
    }
}

struct MultilineTextFieldView_Previews: PreviewProvider {
    static var previews: some View {

        MultilineTextFieldView(placeholder: "Enter private key", value: Binding(get: { "" }, set: { _, _ in }))
    }
}
