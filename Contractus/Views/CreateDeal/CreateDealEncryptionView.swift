//
//  CreateDealEncryptionView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 02.11.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
    static let closeImage = Image(systemName: "xmark")
}

struct CreateDealEncryptionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    
    @State var nextStep: Bool = false
    @State private var enableEncryption: Bool = true
    
    var body: some View {
        ZStack {
            NavigationLink(
                isActive: $nextStep,
                destination: {
                    CreateDealConfirmView()
                        .environmentObject(viewModel)
                },
                label: {
                    EmptyView()
                }
            )
            
            VStack(alignment: .center, spacing: 6) {
                Text(stepTitle)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(R.color.textBase.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                                
                Text(stepSubtitle)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.secondaryText.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 26)
                                
                HStack {
                    Toggle(isOn: $enableEncryption.animation(.easeInOut(duration: 0.1))) {
                        Text("Enable encryption")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(R.color.textFieldBackground.color)
                        .background(R.color.textFieldBackground.color)
                        .cornerRadius(12)
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                }

                Spacer()
                
                Text("You will not be able to add checker after\nyou create a deal")
                    .font(.footnote)
                    .foregroundColor(R.color.textWarn.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                CButton(title: R.string.localizable.commonNext(), style: .primary, size: .large, isLoading: false, action: {
                        viewModel.trigger(.setEncryption(enableEncryption))
                        nextStep.toggle()
                    }
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .baseBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.trigger(.close)
                } label: {
                    Constants.closeImage
                        .resizable()
                        .frame(width: 21, height: 21)
                        .foregroundColor(R.color.textBase.color)
                }
            }
        }
    }
    
    var title: String {
        return "New deal"
    }

    var stepTitle: String {
        return "Detail encryption"
    }
    
    var stepSubtitle: String {
        return "Deal description and files will be encrypted only deal participants can decrypt and view them."
    }
}

#Preview {
    CreateDealEncryptionView()
        .environmentObject(AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))
}
