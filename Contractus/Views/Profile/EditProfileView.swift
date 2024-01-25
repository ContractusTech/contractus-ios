//
//  EditProfileView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 20.01.2024.
//

import SwiftUI

fileprivate enum Constants {
    static let pencil = Image(systemName: "pencil")
    static let arrowRightImage = Image(systemName: "chevron.right")
    static let closeImage = Image(systemName: "xmark")
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            VStack {
                ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                    AsyncImage(url: URL(string: Mock.avatar)) { image in
                        image
                            .resizable()
                            .frame(width: 102, height: 102)
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(51)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 102, height: 102)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    CButton(title: "", icon: Constants.pencil, style: .secondary, size: .small, isLoading: false, roundedCorner: true) { }
                        .overlay(
                            Circle()
                                .stroke(R.color.mainBackground.color, lineWidth: 3)
                        )
                        .padding(.bottom, 12)
                }
                VStack(spacing: 0) {
                    NavigationLink(destination: EditProfileItemView(), label: {
                        ProfileItemView(title: "USERNAME", value: "hudishkin")
                    })
                    Divider()
                    ProfileItemView(title: "NAME", value: "John Doe")
                    Divider()
                    ProfileItemView(title: "ABOUT", value: "Text about your skills...")
                    Divider()
                    ProfileItemView(title: "Link to X", value: "https://x.com/hudishkin ")
                    Divider()
                    ProfileItemView(title: "WEBSITE", value: "https://gdjvmgrfdfjgtr.com")
                }
                .background(
                    R.color.secondaryBackground.color
                        .clipped()
                        .cornerRadius(17)
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                )
                .padding(.horizontal, 8)
                
                HStack {
                    Text("Delete profile")
                        .font(.headline.weight(.medium))
                        .foregroundColor(R.color.redText.color)
                    Spacer()
                    Constants.arrowRightImage
                        .foregroundColor(R.color.whiteSeparator.color)
                }
                .padding(.leading, 20)
                .padding(.vertical, 25)
                .padding(.trailing, 16)
                .background(
                    R.color.secondaryBackground.color
                        .clipped()
                        .cornerRadius(17)
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                )
                .padding(.horizontal, 8)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Constants.closeImage
                        .resizable()
                        .frame(width: 21, height: 21)
                        .foregroundColor(R.color.textBase.color)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(R.string.localizable.commonSave())
                }
            }
        }
        .navigationBarTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct ProfileItemView: View {
    var title: String
    var value: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(R.color.secondaryText.color)
                Text(value)
                    .font(.headline.weight(.medium))
                    .foregroundColor(R.color.textBase.color)
            }
            Spacer()
            Constants.arrowRightImage
                .foregroundColor(R.color.whiteSeparator.color)
        }
        .padding(16)
    }
}
#Preview {
    EditProfileView()
}
