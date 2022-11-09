//
//  DealItemView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 03.08.2022.
//

import SwiftUI

struct DealItemView: View {

    var deal: Deal
    var descryptAction: (() -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(R.color.secondaryBackground.color)
            VStack(alignment: .leading) {
                Text(deal.id)
                Text(deal.createdAt)
                Button("Descrypt") {
                    descryptAction?()
                }
            }

        }
    }
}


import ContractusAPI

struct DealItemView_Previews: PreviewProvider {

    static var previews: some View {
        DealItemView(deal: Mock.deal)
    }
}

