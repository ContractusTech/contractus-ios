//
//  ProfileView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 30.11.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let scanQRImage = Image(systemName: "qrcode")
    static let addPerson = Image(systemName: "person.fill.badge.plus")
    static let pencil = Image(systemName: "pencil.line")
    static let graduationcap = Image(systemName: "graduationcap")
    static let game = Image(systemName: "mappin.and.ellipse")
    static let link = Image(systemName: "link")
    static let dealNew = Image(systemName: "person.line.dotted.person.fill")
    static let dealFinished = Image(systemName: "person.fill.checkmark")
}

struct ProfileView: View {
    @StateObject var viewModel: AnyViewModel<ProfileViewModel.State, ProfileViewModel.Input>

    var body: some View {
        ZStack(alignment: .top) {
            AuthProfileView()
                .environmentObject(viewModel)
//            NewProfileView()
                .padding(.top, 42)
            HStack(alignment: .center) {
                Spacer()
                Text(R.string.localizable.profileTitle())
                    .font(.headline)
                    .foregroundColor(R.color.textBase.color)
                Spacer()
            }
            .frame(height: 42)
            HStack(alignment: .center) {
                Spacer()
                Button {

                } label: {
                    Constants.scanQRImage
                }
            }
            .frame(height: 42)
            .padding(.horizontal, 22)
        }
        .baseBackground()
    }
}

struct AuthProfileView: View {
    @EnvironmentObject var viewModel: AnyViewModel<ProfileViewModel.State, ProfileViewModel.Input>

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Avatar, Name, Nick
                HStack(spacing: 18) {
                    AsyncImage(url: URL(string: Mock.avatar)) { image in
                        image
                            .resizable()
                            .frame(width: 82, height: 82)
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(41)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 82, height: 82)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("John Doe")
                            .font(.title2.weight(.medium))
                            .foregroundColor(R.color.textBase.color)
                        Text("@johndoe")
                            .font(.callout)
                            .foregroundColor(R.color.secondaryText.color)
                        
                    }
                    Spacer()
                    Button(action: {
                        
                    }, label: {
                        if viewModel.state.mode == .public {
                            CButton(title: "", icon: Constants.addPerson, style: .secondary, size: .small, isLoading: false, roundedCorner: true) { }
                        } else {
                            CButton(title: "", icon: Constants.pencil, style: .secondary, size: .small, isLoading: false, roundedCorner: true) { }
                        }
                    })
                }
                .padding(.bottom, 8)

                Text(" • Design Lead @Wander\n • Freelancing at http://michaeldesigns.co \n • Learn UI/UX http://ui-principles.co\n • Learn the design process http://uiuxprocess.com")
                    .font(.callout)
                    .foregroundColor(R.color.textBase.color)
                
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Constants.graduationcap
                            .resizable()
                            .frame(width: 18, height: 18)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(R.color.secondaryText.color)
                        Text("Web designer")
                            .font(.callout)
                            .foregroundColor(R.color.secondaryText.color)
                    }

                    HStack(spacing: 6) {
                        Constants.game
                            .resizable()
                            .frame(width: 18, height: 18)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(R.color.secondaryText.color)
                        Text("New York")
                            .font(.callout)
                            .foregroundColor(R.color.secondaryText.color)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, -8)

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Constants.link
                            .resizable()
                            .frame(width: 18, height: 18)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(R.color.secondaryText.color)
                        Text("www.site.com")
                            .font(.callout)
                            .foregroundColor(R.color.secondaryText.color)
                    }
                    Spacer()
                }

                Divider()
                    .padding(.horizontal, -18)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("DIVIDENTS")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                            Text("$140")
                                .font(.largeTitle)
                        }
                        .padding(.leading, 18)

                        VStack(spacing: 4) {
                            Text("DEALS")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                            Text("123")
                                .font(.largeTitle)
                        }

                        VStack(spacing: 4) {
                            Text("HOLDERS")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                            Text("140")
                                .font(.largeTitle)
                        }

                        VStack(spacing: 4) {
                            Text("FOLLOWERS")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                            Text("140")
                                .font(.largeTitle)
                        }

                        VStack(spacing: 4) {
                            Text("FOLLOWING")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                            Text("40")
                                .font(.largeTitle)
                        }
                        .padding(.trailing, 18)
                    }
                }
                .padding(.horizontal, -18)
                
                VStack(spacing: 0) {
                    HStack {
                        if viewModel.state.mode == .public {
                            Text("PERSONAL TOKEN")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                        } else {
                            Text("MY TOKEN")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                        }
                        Spacer()

                        Text("PRIVATE SALE")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(R.color.blue.color)
                        
                    }
                    .padding(.bottom, 18)

                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: Mock.avatar)) { image in
                            image
                                .resizable()
                                .frame(width: 48, height: 48)
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(41)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 48, height: 48)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Token Name ")
                                .font(.body.weight(.medium))
                                .foregroundColor(R.color.textBase.color) +
                            Text("$CTKS")
                                .font(.body.weight(.medium))
                                .foregroundColor(R.color.secondaryText.color)
                            Text("@johndoe")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(R.color.secondaryText.color)
                            
                        }
                        Spacer()
                    }
                    .padding(.bottom, 10)

                    if viewModel.state.mode == .public {
                        CButton(title: "Buy token", style: .primary, size: .defaultWide, isLoading: false) {}
                    } else {
                        CButton(title: "Details", style: .secondary, size: .defaultWide, isLoading: false) {}
                    }
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: 0.5)
                        .stroke(R.color.baseSeparator.color, lineWidth: 1)
                )

                Text("ACTIVITY")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(R.color.secondaryText.color)

                HStack(spacing: 12) {
                    Constants.dealNew
                        .frame(width: 24, height: 24)
                        .foregroundColor(R.color.yellow.color)
                    Text("Got a new deal")
                        .font(.body.weight(.medium))
                        .foregroundColor(R.color.textBase.color)
                    Spacer()
                    Text("1d ago")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(R.color.secondaryText.color)
                }
                Divider()

                HStack(spacing: 12) {
                    Constants.dealFinished
                        .frame(width: 24, height: 24)
                        .foregroundColor(R.color.baseGreen.color)
                    Text("Finished the deal")
                        .font(.body.weight(.medium))
                        .foregroundColor(R.color.textBase.color)
                    Spacer()
                    Text("3d ago")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(R.color.secondaryText.color)
                }
                Divider()
            }
            .padding(18)
            .padding(.bottom, 50)
        }
    }
}

struct NewProfileView: View {
    var body: some View {
        ZStack {
            VStack() {
                R.image.profileOnboarding.image
                    .resizable()
                    .scaledToFit()
                Spacer()
            }
            VStack(spacing: 16) {
                Spacer()

                Text("Public Profile")
                    .font(.largeTitle.weight(.medium))
                    .padding(.top, 54)
                
                Text("Spread the word about your skills. Create your personalized token and let people invest in your future success.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                
                VStack {
                    CButton(title: "Create with X", style: .primary, size: .large, isLoading: false) {}
                    
                    CButton(title: "More information", style: .secondary, size: .large, isLoading: false) { }
                }
                .padding(EdgeInsets(top: 32, leading: 32, bottom: 16, trailing: 32))
            }
        }
    }
}

#Preview {
    ProfileView(viewModel: .init(ProfileViewModel(mode: .private)))
}
