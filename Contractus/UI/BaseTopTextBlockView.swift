//
//  BaseTopTextBlockView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 23.05.2023.
//

import SwiftUI

struct BaseTopTextBlockView: View {

    let titleText: String
    let subTitleText: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(titleText)
                    .font(.largeTitle.weight(.semibold))
                    .tracking(-1.1)
                Spacer()
            }
            if let subTitleText = subTitleText {
                HStack {
                    Text(subTitleText)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                        .padding(EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0))
                    Spacer()
                }
            }
        }.padding(.bottom, 16)
    }
}

struct BaseTopTextBlockView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                BaseTopTextBlockView(
                    titleText: "Enter private key",
                    subTitleText: "Of the client who will perform the work under the contract.")
            }
        }
    }
}
