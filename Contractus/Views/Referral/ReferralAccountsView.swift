//
//  ReferralAccountsView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 10.09.2023.
//

import SwiftUI

struct ReferralAccountsView: View {
    @EnvironmentObject var viewModel: AnyViewModel<ReferralState, ReferralInput>

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(viewModel.state.accounts, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(ContentMask.mask(from: item.publicKey))
                                Spacer()
                                Text(item.createdAt.timeAgoDisplay())
                                    .font(.caption2)
                                    .foregroundColor(R.color.secondaryText.color)
                            }
                            Text(item.blockchain.capitalized)
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                        .frame(height: 62)
                        .padding(.horizontal, 16)
                        if item != viewModel.state.accounts.last {
                            Divider().foregroundColor(R.color.buttonBorderSecondary.color)
                        }
                    }
                }
                .background(
                    Color(R.color.secondaryBackground()!)
                        .clipped()
                        .cornerRadius(20)
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                )
                .padding(.horizontal, 5)
            }
            .baseBackground()
            .onAppear {
//                EventService.shared.send(event: DefaultAnalyticsEvent.accountsOpen)
            }
            .navigationTitle(R.string.localizable.accountsTitle())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ReferralAccountsView_Previews: PreviewProvider {
    static var previews: some View {
        ReferralAccountsView()
    }
}
