//
//  CreateDealDeadlineView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 02.11.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
    static let closeImage = Image(systemName: "xmark")
    static let defaultDeadlinePerion = 30
}

struct CreateDealDeadlineView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    
    @State var nextStep: Bool = false
    @State var encryptionStep: Bool = false
    @State private var deadline: Date = Calendar.current.date(byAdding: .day, value: Constants.defaultDeadlinePerion, to: Date())!

    var allowDates: PartialRangeFrom<Date> {
        Calendar.current.date(byAdding: .day, value: 1, to: Date())!...
    }

    var body: some View {
        ZStack {
            NavigationLink(
                isActive: $nextStep,
                destination: {
                    CreateDealBondView()
                        .environmentObject(viewModel)
                },
                label: {
                    EmptyView()
                }
            )
            
            NavigationLink(
                isActive: $encryptionStep,
                destination: {
                    CreateDealEncryptionView()
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
                                
                DatePicker(R.string.localizable.commonDate(), selection: $deadline, in: allowDates, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding(12)
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                
                Text(R.string.localizable.newDealDeadlineHint(Date.fullRelativeDateFormatted(from: .now, to: deadline)))
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.textBase .color)
                    .padding(.top, 6)

                Spacer()
                
                Text(R.string.localizable.newDealAbleChangeHint())
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.secondaryText.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                CButton(
                    title: R.string.localizable.commonNext(),
                    style: .primary,
                    size: .large,
                    isLoading: false,
                    action: {
                        viewModel.trigger(.setDeadline(deadline))
                        if viewModel.state.checkType == .checker {
                            encryptionStep.toggle()
                        } else {
                            nextStep.toggle()
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
        return R.string.localizable.newDealDeadlineTitle()
    }
    
    var stepSubtitle: String {
        return R.string.localizable.newDealDeadlineSubtitle()
    }
}

#Preview {
    CreateDealDeadlineView()
        .environmentObject(AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))
}
