//
//  ReferralView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 15.08.2023.
//

import SwiftUI
import Shimmer

fileprivate enum Constants {
    static let successCopyImage = Image(systemName: "checkmark")
    static let copyImage = Image(systemName: "square.on.square")
}

struct ReferralView: View {

    @State var copiedNotification: Bool = false
    @State var promoIsPresented: Bool = false

    @StateObject var viewModel: AnyViewModel<ReferralState, ReferralInput>

    init() {
        self._viewModel = .init(
            wrappedValue: .init(ReferralViewModel(
                referralService: APIServiceFactory.shared.makeReferralsService()
            )
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {

                // MARK: - Loading view
                if viewModel.state.state == .loading {
                    LoadingReferralView()
                } else {

                    // MARK: - Promocode
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(R.string.localizable.referralPromocodeTitle())
                                    .font(.footnote.weight(.semibold))
                                    .textCase(.uppercase)
                                    .foregroundColor(R.color.secondaryText.color)
                                Spacer()
                            }
                            if let promocode = viewModel.state.promocode {
                                HStack(spacing: 16) {
                                    Text(promocode)
                                        .font(.largeTitle.weight(.semibold))
                                        .textCase(.uppercase)
                                    
                                    Button {
                                        copiedNotification = true
                                        ImpactGenerator.soft()
                                        UIPasteboard.general.string = promocode
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                                            copiedNotification = false
                                        })
                                        EventService.shared.send(event: DefaultAnalyticsEvent.referralCodeCopyTap)
                                    } label: {
                                        HStack {
                                            if copiedNotification {
                                                Constants.successCopyImage
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 20, height: 20)
                                                    .foregroundColor(R.color.baseGreen.color)
                                            } else {
                                                Constants.copyImage
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 20, height: 20)
                                                    .foregroundColor(R.color.textBase.color)
                                            }
                                        }
                                        .frame(width: 24, height: 24)
                                    }
                                }
                            } else {
                                CButton(title: R.string.localizable.referralPromocodeRequest(), style: .secondary, size: .small, isLoading: false) {
                                    EventService.shared.send(event: DefaultAnalyticsEvent.referralCodeCreateTap)
                                    viewModel.trigger(.create)
                                }
                            }
                            Text(R.string.localizable.referralPromocodeSubtitle())
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                            
                        }
                    }
                    .padding(EdgeInsets(top: 16, leading: 13, bottom: 20, trailing: 13))
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))

                    // MARK: - Bonus
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(R.string.localizable.referralBonusTitle())
                                    .font(.footnote.weight(.semibold))
                                    .textCase(.uppercase)
                                    .foregroundColor(R.color.secondaryText.color)
                                Spacer()
                            }
                            
                            if viewModel.state.state == .applied {
                                CButton(title: R.string.localizable.referralPromocodeApplied(), style: .success, size: .small, isLoading: false, isDisabled: true) {}
                            } else {
                                CButton(title: R.string.localizable.referralPromocodeApply(), style: .secondary, size: .small, isLoading: false) {
                                    EventService.shared.send(event: DefaultAnalyticsEvent.referralApplyCodeFormTap)
                                    promoIsPresented.toggle()
                                }
                            }

                            Text(R.string.localizable.referralBonusSubtitle())
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                        }
                    }
                    .padding(EdgeInsets(top: 16, leading: 13, bottom: 20, trailing: 13))
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    
                    // MARK: - Prizes
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(R.string.localizable.referralAirdropTitle())
                                    .font(.footnote.weight(.semibold))
                                    .textCase(.uppercase)
                                    .foregroundColor(R.color.secondaryText.color)
                                    .padding(.bottom, 10)

                                Spacer()
                            }

                            ForEach(viewModel.state.prizes.indices, id: \.self) { index in
                                ReferralPrizeItemView(item: viewModel.state.prizes[index])
                                if index != viewModel.state.prizes.count - 1 {
                                    Divider().foregroundColor(R.color.buttonBorderSecondary.color)
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 16, leading: 13, bottom: 20, trailing: 13))
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                }
            }
            .padding(.horizontal, 5)
        }
        .baseBackground()
        .onAppear {
            EventService.shared.send(event: DefaultAnalyticsEvent.referralOpen)
        }
        .navigationTitle(R.string.localizable.referralTitle())
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $promoIsPresented) {
            PromocodeView()
                .environmentObject(viewModel)
        }
    }
}

struct LoadingReferralView: View {

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(R.string.localizable.referralPromocodeTitle())
                    .font(.footnote.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundColor(R.color.secondaryText.color)

                Text(R.string.localizable.commonEmpty())
                    .font(.largeTitle.weight(.semibold))
                    .opacity(0)

                Text(R.string.localizable.commonEmpty())
                    .opacity(0)
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 16, leading: 13, bottom: 20, trailing: 13))
        .background(R.color.secondaryBackground.color)
        .cornerRadius(20)
        .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
        .shimmering()
    }
}

struct ReferralPrizeItemView: View {
    var item: PrizeItem
    
    var body: some View {
        HStack {
            Text(item.title)
                .font(.footnote.weight(.regular))
                .foregroundColor(item.type == .unknown ? R.color.textWarn.color : R.color.textBase.color)
            Spacer()
            
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.footnote.weight(.regular))
                    .foregroundColor(R.color.secondaryText.color)
                    .opacity(item.type == .unknown ? 0 : 1)
                Spacer()
            }
            Text("\(item.applied ? "+" : "")\(item.amount)")
                .font(.footnote.weight(.regular))
                .foregroundColor(item.applied ? R.color.baseGreen.color : R.color.secondaryText.color)
                .opacity(item.type == .unknown ? 0 : 1)
         }
    }
}

struct ReferralView_Previews: PreviewProvider {
    static var previews: some View {
        ReferralView()
    }
}
