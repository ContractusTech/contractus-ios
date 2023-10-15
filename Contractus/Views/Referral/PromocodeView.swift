//
//  PromocodeView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 15.08.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
}

struct PromocodeView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: AnyViewModel<ReferralState, ReferralInput>

    @State var value: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Text(R.string.localizable.promocodeEnter())
                        .font(.largeTitle.weight(.regular))
                        .foregroundColor(R.color.secondaryText.color)
                        .opacity(value.isEmpty ? 1 : 0)
                        .animation(Animation.easeInOut(duration: 0.1), value: value.isEmpty)
                    
                    TextField("", text: $value)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.largeTitle.weight(.regular))
                        .multilineTextAlignment(.center)
                        .onChange(of: value) { newValue in
                            viewModel.trigger(.resetError)
                        }
                }
                
                if case .error(let message) = viewModel.errorState {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(R.color.redText.color)
                        .padding(.top, 20)
                        .multilineTextAlignment(.center)
                        .opacity(value.isEmpty ? 0 : 1)
                        .animation(Animation.easeInOut(duration: 0.2), value: value.isEmpty)
                } else {
                    Text(R.string.localizable.commonError())
                        .font(.footnote.weight(.semibold))
                        .padding(.top, 20)
                        .opacity(0)
                }
                
                Spacer()
                CButton(title: R.string.localizable.promocodeApply(), style: .primary, size: .large, isLoading: false, isDisabled: value.isEmpty) {
                    EventService.shared.send(event: DefaultAnalyticsEvent.referralApplyCodeTap)
                    viewModel.trigger(.apply(value)) {}
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 18)
            .baseBackground()
            .navigationTitle(R.string.localizable.promocodeTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Constants.closeImage
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(R.color.textBase.color)

                    }
                }
            }
            .onChange(of: viewModel.state.state) { newValue in
                switch newValue {
                case .applied:
                    viewModel.trigger(.resetError)
                    presentationMode.wrappedValue.dismiss()
                default:
                    return
                }
                
            }
        }
    }
}

struct PromocodeView_Previews: PreviewProvider {
    static var previews: some View {
        PromocodeView()
    }
}
