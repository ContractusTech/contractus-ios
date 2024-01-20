//
//  PeopleView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 19.01.2024.
//

import SwiftUI

fileprivate enum Constants {
    static let addPerson = Image(systemName: "person.fill.badge.plus")
    static let personBadge = Image(systemName: "person.crop.circle.badge")
}

struct PeopleView: View {
    @StateObject var viewModel: AnyViewModel<PeopleViewModel.State, PeopleViewModel.Input>

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack {
                    FindProfileView()
                        .padding(.horizontal, 20)
                        .environmentObject(viewModel)
                    .padding(.top, 42)
                    
                    PeopleListView()
                }
            }
            HStack(alignment: .center) {
                Spacer()
                Text(R.string.localizable.peopleTitle())
                    .font(.headline)
                    .foregroundColor(R.color.textBase.color)
                Spacer()
            }
            .frame(height: 42)
            .padding(.horizontal, 22)
            .baseBackground()
        }
        .baseBackground()
    }
}

struct FindProfileView: View {
    var body: some View {
        VStack(spacing: 0) {
            Constants.personBadge
                .resizable()
                .foregroundColor(R.color.secondaryText.color)
                .frame(width: 48, height: 40)
                .padding(.top, 36)
            Text("You'll see updates from the\npeople you're subscribed.")
                .foregroundColor(R.color.secondaryText.color)
                .padding(.top, 22)
                .multilineTextAlignment(.center)
            CButton(title: "Find people", style: .primary, size: .defaultWide, isLoading: false) {}
                .padding(.horizontal, 38)
                .padding(.top, 40)
                .padding(.bottom, 34)

        }
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .inset(by: 0.5)
                .stroke(Color(red: 0.84, green: 0.85, blue: 0.91), lineWidth: 1)
            
        )
    }
}

struct PeopleListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("POPULAR PEOPLE")
                .font(.footnote.weight(.semibold))
                .foregroundColor(R.color.secondaryText.color)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)

            PeopleItemView(name: "John Doe", nick: "@johndoe")
            Divider()
                .padding(.horizontal, 16)
            PeopleItemView(name: "Emely Drimmer", nick: "@drimmer")
            Divider()
                .padding(.horizontal, 16)
            PeopleItemView(name: "Emely Drimmer", nick: "@drimmer")

            CButton(title: "More", style: .secondary, size: .defaultWide, isLoading: false) {}
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

        }
    }
}

struct PeopleItemView: View {
    var name: String
    var nick: String
    
    var body: some View {
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
                Text(name)
                    .font(.body.weight(.medium))
                    .foregroundColor(R.color.textBase.color)
                Text(nick)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(R.color.secondaryText.color)
                
            }
            Spacer()
            CButton(title: "", icon: Constants.addPerson, style: .secondary, size: .small, isLoading: false, roundedCorner: true) { }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
}

#Preview {
    PeopleView(viewModel: .init(PeopleViewModel()))
}
