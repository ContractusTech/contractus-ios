//
//  OnboardingPageView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 23.08.2023.
//

import SwiftUI

struct OnboardingPageView: View {
    var page: OnboardingPageModel

    var body: some View {
        let width = UIScreen.main.bounds.size.width
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let imageName = page.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .saturation(0.0)
                        .cornerRadius(20)
                        .padding(8)
                        .padding(.bottom, 30)
                }
                if let imageUrl = page.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .saturation(0.0)
                            .cornerRadius(20)
                            .padding(8)
                            .padding(.bottom, 30)
                    } placeholder: {
                        ProgressView()
                            .frame(width: width - 16, height: width - 16)
                            .padding(8)
                            .padding(.bottom, 30)
                    }
                }

                if page.isChangelog {
                    Label(text: R.string.localizable.commonChanges(), type: .primary, size: .large)
                        .offset(x: -20, y: 20)
                }
            }

            Text(page.title ?? "")
                .font(.largeTitle.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            Text(LocalizedStringKey(page.description ?? ""))
                .font(.body)
                .tint(R.color.blue.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
            
            Spacer()
        }
    }
}

struct OnboardingPageView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPageView(
            page: OnboardingPageModel(
                imageName: nil,
                imageUrl: "https://s3-alpha-sig.figma.com/img/4bea/bc5d/b6b5192b004b95281f00d983d8c68f21?Expires=1693785600&Signature=kR2DMrQdF8rIw3qgQRdRw4rbkwMFoUupfguJyEJA09v11HZw6d7HOEh7sW5gU4EHFMAJws59Qs4wkHA8QHaPlwIcLJeNzYKtI~NEZtBwIwE9b8MhMmVYZf0Uh-AtvTogbeGkSJxjbmH429g~fxVaUkkL9hwU~6sVcDdDgp9ZLeidjixhH~RGVqZZe6pjPFUlyrpMUJ63taNrfPUJrZzeJgC0grgcz39zdWBaFkQvaSvz16k1jR9L7MUiaR4k5ZUsUWHPhFomEwH3pX3bIquQGEf5XP1vtawAMdPg2ouo7NizowEGCBPyqR4VG6KrWR0Sf1rte5sp0cpvt9aCZ0xgxA__&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4",
                title: "Title onboarding",
                description: "Visit Apple: [click here](https://apple.com)",
                buttonType: .next,
                isChangelog: false
            )
        )

        OnboardingPageView(
            page: OnboardingPageModel(
                imageName: nil,
                imageUrl: "https://s3-alpha-sig.figma.com/img/4bea/bc5d/b6b5192b004b95281f00d983d8c68f21?Expires=1693785600&Signature=kR2DMrQdF8rIw3qgQRdRw4rbkwMFoUupfguJyEJA09v11HZw6d7HOEh7sW5gU4EHFMAJws59Qs4wkHA8QHaPlwIcLJeNzYKtI~NEZtBwIwE9b8MhMmVYZf0Uh-AtvTogbeGkSJxjbmH429g~fxVaUkkL9hwU~6sVcDdDgp9ZLeidjixhH~RGVqZZe6pjPFUlyrpMUJ63taNrfPUJrZzeJgC0grgcz39zdWBaFkQvaSvz16k1jR9L7MUiaR4k5ZUsUWHPhFomEwH3pX3bIquQGEf5XP1vtawAMdPg2ouo7NizowEGCBPyqR4VG6KrWR0Sf1rte5sp0cpvt9aCZ0xgxA__&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4",
                title: "Title onboarding",
                description: "Visit Apple: [click here](https://apple.com)",
                buttonType: .next,
                isChangelog: true
            )
        )
    }
}
