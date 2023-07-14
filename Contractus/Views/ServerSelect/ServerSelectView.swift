//
//  ServerSelectView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 27.02.2023.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let checkmarkImage = Image(systemName: "checkmark")
}

struct ServerSelectView: View {
    #if DEBUG
    @State private var items: [ServerType] =  [.developer(), .production(), .local()]
    #else
    @State private var items: [ServerType] =  [.developer(), .production()]
    #endif
    @State var selectedItem: ServerType?

    @State private var confirmAlert: Bool = false

    var body: some View {
        Form {
            List {
                ForEach(items, id: \.self.title) { item in
                    HStack(spacing: 12) {
                        Text(item.title)
                        Spacer()
                        if self.selectedItem?.title == item.title {
                            Constants.checkmarkImage.foregroundColor(R.color.accentColor.color)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if item.apiURL != self.selectedItem?.apiURL {
                            self.selectedItem = item
                            ConfigStorage.setServer(server: item)
                            confirmAlert.toggle()
                        }
                    }
                }
            }
        }
        .baseBackground()
        .navigationTitle("Server")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedItem = ConfigStorage.getServer(defaultServer: .developer())
        }
        .alert(isPresented: $confirmAlert) {
            Alert(
                title: Text("Warning"),
                message: Text("Application will be closed to apply new server settings, you must start it again manually"),
                dismissButton: .default(Text("OK, Undestand"), action: {
                    exit(0)
                })
            )
        }
    }
}

struct ServerSelectView_Previews: PreviewProvider {
    static var previews: some View {
        ServerSelectView()
    }
}
