//
//  CreateDealConfirmView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 02.11.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
    static let closeImage = Image(systemName: "xmark")
    static let lockImage = Image(systemName: "lock.fill")
}

struct CreateDealConfirmItemView: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(R.color.textBase.color)
                .multilineTextAlignment(.leading)
            Constants.lockImage
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(R.color.secondaryText.color)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }
}

struct CreateDealConfirmView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    
    @State var nextStep: Bool = false
    
    var body: some View {
        ZStack {
           VStack(alignment: .center, spacing: 6) {
                Text(stepTitle)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(R.color.textBase.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 26)

               HStack(alignment: .center, spacing: 4) {
                   Text("Deadline")
                       .font(.body)
                       .fontWeight(.semibold)
                       .foregroundColor(R.color.textBase.color)
                       .multilineTextAlignment(.leading)
                   Spacer()

                   Text(viewModel.state.deadline?.asDateFormatted() ?? "")
                       .font(.body)
                       .fontWeight(.medium)
                       .foregroundColor(R.color.secondaryText.color)
                       .multilineTextAlignment(.leading)
               }
               .padding(.vertical, 20)
               .padding(.horizontal, 16)
               .background(R.color.secondaryBackground.color)
               .cornerRadius(20)
               .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
               .padding(.bottom, 6)

               VStack(spacing: 0) {
                   CreateDealConfirmItemView(
                        title: "Your role",
                        value: viewModel.state.role == .client ? "Client" : "Executor"
                   )
                   
                   Divider()

                   CreateDealConfirmItemView(
                       title: "Enable encryption",
                       value: viewModel.state.encryption ?? false ? "On" : "Off"
                   )
                   
                   Divider()

                   CreateDealConfirmItemView(
                       title: "Allow checker",
                       value: viewModel.state.checkType == .checker ? "Yes" : "No"
                   )
                   
                   if viewModel.state.checkType != .checker {
                       Divider()

                       CreateDealConfirmItemView(
                        title: "Performance bond",
                        value: viewModel.state.bondType?.shortTitle ?? ""
                       )
                   }
               }
               .background(R.color.secondaryBackground.color)
               .cornerRadius(20)
               .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)

               Spacer()
               
               CButton(title: R.string.localizable.commonCreate(), style: .primary, size: .large, isLoading: false, action: {
                   EventService.shared.send(event: ExtendedAnalyticsEvent.newDealCreateTap(
                       viewModel.state.role!,
                       viewModel.state.checkType == .checker,
                       viewModel.state.bondType ?? .none,
                       viewModel.state.encryption ?? false
                   ))
                   viewModel.trigger(.createDeal)
               })
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
        return "Confirmation"
    }
    
    var stepSubtitle: String {
        return "Deal description and files will be encrypted only deal participants can decrypt and view them."
    }
}

#Preview {
    CreateDealConfirmView()
        .environmentObject(AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))
}
