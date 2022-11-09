//
//  ImportPrivateKeyView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.10.2022.
//

import SwiftUI

struct ImportPrivateKeyView: View {

    @EnvironmentObject var viewModel: AnyViewModel<EnterState, EnterInput>

    @State var privateKey: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack {
                VStack(alignment: .center, spacing: 24) {

                    Text("Import private key")
                        .font(.largeTitle)
                    Text("If you already have an account, enter the private key").font(.body)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    MultilineTextFieldView(placeholder: "Enter private key", value: $privateKey)
                    .background(R.color.thirdBackground.color)
                    .cornerRadius(10)

                }
                Spacer()

                HStack {
                    Button {


                    } label: {
                        HStack {
                            Spacer()
                            Text("Import")
                            Spacer()
                        }
                    }.buttonStyle(PrimaryLargeButton())
                }
            }

            .padding()
            .padding(.bottom, 24)
            .navigationBarColor()
            .baseBackground()
            .tintIfCan(R.color.textBase.color)
        }
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.bottom)


    }
}

struct ImportPrivateKeyView_Previews: PreviewProvider {
    static var previews: some View {
        ImportPrivateKeyView()
    }
}
