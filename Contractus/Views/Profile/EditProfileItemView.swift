//
//  EditProfileItemView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 25.01.2024.
//

import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
}

struct EditProfileItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("USERNAME")
                .font(.footnote.weight(.medium))
                .foregroundColor(R.color.secondaryText.color)
            TextField("", text: $value)
                .textFieldStyle(LargeTextFieldStyle())
                .multilineTextAlignment(.leading)
                .background(R.color.textFieldBackground.color)
                .cornerRadius(11)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .inset(by: 0.5)
                        .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                )
                .onChange(of: value) { newValue in

                }
            Spacer()
        }
        .padding(.all, 16)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Constants.backImage
                        .resizable()
                        .frame(width: 12, height: 21)
                        .foregroundColor(R.color.textBase.color)
                }
            }            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(R.string.localizable.commonDone())
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    EditProfileItemView()
}
