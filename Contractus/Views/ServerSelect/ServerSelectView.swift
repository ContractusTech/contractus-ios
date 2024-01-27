//
//  ServerSelectView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 27.02.2023.
//

import SwiftUI
import ContractusAPI
import netfox

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

    @State var enableLogs: Bool = NFX.sharedInstance().isStarted()

    @State private var confirmAlert: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Server"), footer: Text("When you tap it, the application will close")) {
                ForEach(items, id: \.title) { item in
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
            Section(header: Text("Request Logs")) {
                HStack(spacing: 12) {
                    Toggle(isOn: $enableLogs) {
                        Text("Enabled")
                    }
                }

                HStack(spacing: 12) {
                    Text("View logs")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    NFX.sharedInstance().show()
                }
            }

            Section(header: Text("Info")) {
                ForEach(AppManagerImpl.shared.debugInfo(), id: \.self) { item in
                    HStack {
                        Text(item)
                            .font(.callout)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = item
                            ImpactGenerator.light()
                        } label: {
                            Text("Copy")
                                .tint(.blue)
                        }
                    }

                }
            }

            Section(header: Text("Actions")) {
#if DEBUG
                Button {
                    AppManagerImpl.shared.debugClearAuth()
                    confirmAlert.toggle()
                } label: {
                    Text("Clear auth")
                        .tint(.blue)
                }
#endif
                Button {
                    UtilsStorage.shared.debugClearSettings(account: AppManagerImpl.shared.currentAccount)
                } label: {
                    Text("Clear cache")
                        .tint(.blue)
                }
            }

        }
        .onChange(of: enableLogs) { newValue in
            if newValue {
                NFX.sharedInstance().start()
            } else {
                NFX.sharedInstance().stop()
            }

        }
        .baseBackground()
        .navigationTitle("Server")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedItem = AppConfig.serverType
        }
        .alert(isPresented: $confirmAlert) {
            Alert(
                title: Text("Warning"),
                message: Text("Application will be closed to apply new settings, you must start it again manually"),
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
