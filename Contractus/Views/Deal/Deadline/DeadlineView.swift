//
//  DeadlineView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.05.2023.
//

import SwiftUI
import ContractusAPI

struct DeadlineView: View {

    enum AlertType: Identifiable {
        var id: String { "\(self)" }
        case error(String)
    }

    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AnyViewModel<DeadlineViewModel.State, DeadlineViewModel.Input>
    @State private var deadline: Date
    @State private var alertType: AlertType?

    var callback: ((Deal) -> Void)? = nil

    var allowDates: PartialRangeFrom<Date> {
        Calendar.current.date(byAdding: .day, value: 1, to: Date())!...
    }

    init(viewModel: AnyViewModel<DeadlineViewModel.State, DeadlineViewModel.Input>, callback: ( (Deal) -> Void)? = nil) {

        self._viewModel = .init(wrappedValue: viewModel)
        self._deadline = .init(wrappedValue: viewModel.deal.deadline ?? Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        self.callback = callback
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    DatePicker("Date", selection: $deadline,  in: allowDates, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(12)
                        .background(R.color.secondaryBackground.color)
                        .cornerRadius(20)
                        .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Deadline of deal")
                            .font(.footnote)
                        Text(deadline.asDateFormatted())
                            .font(.title2.weight(.semibold))
                        Text("You must complete the deal by this date or the deal will be stopped and funds will be refunded to all parties. The service fee is not refundable.")
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)
                    }
                    .padding(16)
                    .background(content: {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(R.color.baseSeparator.color)
                    })

                    Spacer()
                }
                .padding(8)
            }
            .onChange(of: viewModel.state.errorState) { value in
                switch value {
                case .error(let errorMessage):
                    self.alertType = .error(errorMessage)
                case .none:
                    self.alertType = nil
                }
            }
            .onChange(of: viewModel.state.state) { value in
                switch value {
                case .success:
                    callback?(viewModel.deal)
                    presentationMode.wrappedValue.dismiss()
                case .none, .loading:
                    break
                }
            }
            .alert(item: $alertType, content: { type in
                switch type {
                case .error(let message):
                    return Alert(
                        title: Text(R.string.localizable.commonError()),
                        message: Text(message),
                        dismissButton: .default(Text(R.string.localizable.commonOk()), action: {
                            viewModel.trigger(.hideError)
                        }))
                }
            })


            .baseBackground()
            .safeAreaInset(edge: .bottom, content: {
                CButton(title: R.string.localizable.commonSave(), style: .primary, size: .large, isLoading: viewModel.state.state == .loading, isDisabled: deadline <= Date()) {
                    viewModel.trigger(.updateDeadline(deadline))
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            })
            .navigationBarTitle(Text("Select deadline"), displayMode: .inline)

        }
    }
}

struct DeadlineView_Previews: PreviewProvider {
    static var previews: some View {
        DeadlineView(viewModel: .init(DeadlineViewModel(deal: Mock.deal, account: Mock.account, dealService: nil)))
    }
}
