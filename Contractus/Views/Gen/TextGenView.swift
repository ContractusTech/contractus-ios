import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let arrowDown = Image(systemName: "chevron.down")
    static let arrowUp = Image(systemName: "chevron.up")
    static let plainText = Image(systemName: "doc.plaintext")
    static let paste = Image(systemName: "doc.on.clipboard")
}


struct TextGenView: View {

    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<TextGenViewModel.State, TextGenViewModel.Input> = .init(TextGenViewModel(aiService: APIServiceFactory.shared.makeAIService()))

    @State private var content: String = ""
    @State private var showExamples: Bool = false
    var callback: (String) -> Void
    @FocusState var isInputActive: Bool
    var body: some View {
        ScrollView {
            VStack(spacing: 6) {

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $content)
                        .frame(height: 90)
                        .disabled(viewModel.state.loading)
                        .opacity(viewModel.state.loading ? 0.4 : 1.0)
                        .setBackground(color: R.color.textFieldBackground.color)
                        .focused($isInputActive)

                    if content.isEmpty {
                        Text(R.string.localizable.dealTextEditorEditorPlaceholder())
                            .padding(EdgeInsets(top: 8, leading: 12, bottom: 0, trailing: 5))
                            .foregroundColor(R.color.secondaryText.color)
                            .allowsHitTesting(false)
                    }


                }
                .padding(4)
                .background(R.color.textFieldBackground.color)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .inset(by: 0.5)
                        .stroke(R.color.textFieldBorder.color, lineWidth: 1))

                HStack {

                    CButton(title: R.string.localizable.aiGenPrompts(), icon: (showExamples ? Constants.arrowUp : Constants.arrowDown), style: .clear, size: .default, isLoading: false) {
                        showExamples.toggle()
                    }
                    
                    Spacer()
                    CButton(title: R.string.localizable.aiGenGenerate(), style: .primary, size: .default, isLoading: viewModel.state.loading) {

                        viewModel.trigger(.generate(content))
                    }
                }
                .padding(.vertical, 4)

                if showExamples {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.state.prompts, id: \.id) { item in
                                promptView(item: item)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    }
                }
            }

            Divider()


            if !viewModel.state.generatedText.isEmpty {
                VStack {
                    HStack {
                        Text(R.string.localizable.aiGenResultTitle())
                            .font(.title2.weight(.semibold))
                        Spacer()

                        CButton(title: R.string.localizable.aiGenPaste(), icon: Constants.paste, style: .secondary, size: .default, isLoading: false) {
                            callback(viewModel.state.generatedText)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    Spacer()
                    Text(viewModel.state.generatedText)
                        .padding(.bottom, 8)
                }
                .padding(12)
                .background(R.color.secondaryBackground.color)
                .cornerRadius(20)
                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
            }

        }
        .padding(8)
        .navigationTitle(R.string.localizable.aiGenTitle())
        .navigationViewStyle(StackNavigationViewStyle())
        .baseBackground()
        .onAppear {
            isInputActive = true
        }
    }

    @ViewBuilder
    func promptView(item: AIPrompt) -> some View {
        VStack {
            MultilineText(item.text, font: .preferredFont(forTextStyle: .footnote), textAlignment: .left, textColor: R.color.textBase(), preferredMaxLayoutWidth: 240)

            HStack {
                CButton(title: R.string.localizable.aiGenUseIt(), style: .secondary, size: .small, isLoading: false) {
                    content = item.text
                }
                Spacer()
            }
        }
        .padding(12)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(R.color.secondaryText.color)
                RoundedRectangle(cornerRadius: 20)
                    .stroke()
                    .fill(R.color.baseSeparator.color)
            }

        }
    }
}

#Preview {
    TextGenView { _ in

    }
}
