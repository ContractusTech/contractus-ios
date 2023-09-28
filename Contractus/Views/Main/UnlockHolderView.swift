//
//  UnlockHolderView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.09.2023.
//

import SwiftUI

struct UnlockHolderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Unlock Holder Mode")
                    .font(.title2)
            }
            .padding(.bottom, 6)
            .padding(.top, 6)
            itemView(title: "Buy for SOL or USDC tokens", description: "", disabled: false, loading: false) {
            }

            itemView(title: "Buy on CEX or DEX", description: "", disabled: false, loading: false) {
                

            }

            Spacer()
        }
        .padding(20)
    }
    
    @ViewBuilder
    func itemView(title: String, description: String, disabled: Bool, loading: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(alignment: .center) {

                VStack(alignment: .leading, spacing: 6){
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(R.color.textBase.color)
                    if !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(R.color.secondaryText.color)
                    }
                }
                Spacer()
                if loading {
                    ProgressView()
                }

            }
            .padding()
            .background(content: {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(R.color.baseSeparator.color, lineWidth: 1)
            })
            .opacity(disabled ? 0.6 : 1.0)
        }
        .disabled(disabled)

    }
}

struct UnlockHolderView_Previews: PreviewProvider {
    static var previews: some View {
        UnlockHolderView()
    }
}
