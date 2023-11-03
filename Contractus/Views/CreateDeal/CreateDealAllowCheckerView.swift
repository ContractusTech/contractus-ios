//
//  CreateDealAllowCheckerView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 02.11.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
    static let closeImage = Image(systemName: "xmark")
}

struct CreateDealAllowCheckerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    
    @State var nextStep: Bool = false
    @State var deadlineStep: Bool = false
    @State private var allowChecker: Bool = false
    
    var body: some View {
        ZStack {
            NavigationLink(
                isActive: $nextStep,
                destination: {
                    CreateDealCheckerView()
                        .environmentObject(viewModel)
                },
                label: {
                    EmptyView()
                }
            )
            
            NavigationLink(
                isActive: $deadlineStep,
                destination: {
                    CreateDealDeadlineView()
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
                    Toggle(isOn: $allowChecker.animation(.easeInOut(duration: 0.1))) {
                        Text(R.string.localizable.newDealCheckTitle())
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
                .padding(16)
                .background(content: {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(R.color.textFieldBackground.color)
                        .background(R.color.textFieldBackground.color)
                        .cornerRadius(12)
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                })

                Spacer()
                
                Text(R.string.localizable.newDealNotAbleChangeHint())
                    .font(.footnote)
                    .foregroundColor(R.color.textWarn.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                CButton(title: R.string.localizable.commonNext(), style: .primary, size: .large, isLoading: false, action: {
                        viewModel.trigger(.setCheckType(allowChecker ? .checker : .none))
                        if allowChecker {
                            nextStep.toggle()
                        } else {
                            deadlineStep.toggle()
                        }
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
        return R.string.localizable.newDealTitle()
    }

    var stepTitle: String {
        return R.string.localizable.newDealCheckerTitle()
    }
    
    var stepSubtitle: String {
        return R.string.localizable.newDealCheckerSubtitle()
    }
}

#Preview {
    CreateDealAllowCheckerView()
        .environmentObject(AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))
}
