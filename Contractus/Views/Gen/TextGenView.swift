import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let arrowDown = Image(systemName: "chevron.down")
    static let arrowUp = Image(systemName: "chevron.up")
    static let plainText = Image(systemName: "doc.plaintext")
    static let paste = Image(systemName: "doc.on.clipboard")
    static let backwardImage = Image(systemName: "arrow.uturn.backward")
    static let forwardImage = Image(systemName: "arrow.uturn.forward")
    static let textImage = Image(systemName: "character.cursor.ibeam")
}

struct TextGenView: View {

    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<TextGenViewModel.State, TextGenViewModel.Input> = .init(TextGenViewModel(aiService: APIServiceFactory.shared.makeAIService()))

    @State private var content: String = ""
    @State var contractText: String = ""
    @State private var showExamples: Bool = false
    @State private var showForm: Bool = false
    @State var undoManager: UndoManager?
    @FocusState var isContentInputActive: Bool
    @FocusState var isContractInputActive: Bool

    var callback: (String) -> Void

    var body: some View {
        VStack {
            if !showForm {
                VStack(spacing: 6) {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $content)
                            .frame(height: 90)
                            .disabled(viewModel.state.state == .loading)
                            .opacity(viewModel.state.state == .loading ? 0.4 : 1.0)
                            .setBackground(color: R.color.textFieldBackground.color)
                            .focused($isContentInputActive)

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
                        if !viewModel.state.prompts.isEmpty {
                            CButton(title: R.string.localizable.aiGenPrompts(), icon: (showExamples ? Constants.arrowUp : Constants.arrowDown), style: .clear, size: .default, isLoading: false) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showExamples.toggle()
                                }
                            }
                        }
                        Spacer()
                        CButton(title: R.string.localizable.aiGenGenerate(), 
                                style: .primary,
                                size: .default,
                                isLoading: viewModel.state.state == .loading,
                                isDisabled: content.isEmpty
                        ) {

                            self.isContentInputActive = false
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
                .padding(12)
                .background(R.color.secondaryBackground.color)
                .cornerRadius(20)
                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
            }

            if !contractText.isEmpty {

                HStack {
                    Text(R.string.localizable.aiGenResultTitle())
                        .font(.title2.weight(.semibold))
                    Spacer()

                    CButton(title: R.string.localizable.aiGenContinue(), icon: Constants.paste, style: .secondary, size: .default, isLoading: false) {
                        callback(contractText)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 4)
                .padding(.horizontal, 8)

                VStack {
                    UndoTextView(content: $contractText, undoManager: $undoManager)
                        .padding(8)
                        .padding(.bottom, 32)
                        .focused($isContractInputActive)
                }
                .background(R.color.textFieldBackground.color)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .inset(by: 0.5)
                        .stroke(R.color.textFieldBorder.color, lineWidth: 1))
                .overlay(alignment: .bottom) {
                    controlsView()
                }
                .padding(8)
            } else {
                Spacer()
                Constants.textImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52, alignment: .center)
                    .foregroundColor(R.color.fourthBackground.color)
                    .opacity(0.6)
            }
            Spacer()
        }
        .onTapGesture {
            if isContractInputActive { return }

            self.isContentInputActive = false
        }

        .navigationTitle(R.string.localizable.aiGenTitle())
        .navigationViewStyle(StackNavigationViewStyle())
        .baseBackground()
        .onChange(of: isContractInputActive) { focus in
            withAnimation(.easeInOut(duration: 0.2)) {
                showForm = focus
            }
        }
        .onAppear {
            contractText = viewModel.state.generatedText
        }
        .onChange(of: viewModel.state.state) { newState in
            switch newState {
            case .loading:
                break
            case .loaded:
                contractText = viewModel.state.generatedText
            case .none:
                break
            }
        }

    }

    @ViewBuilder
    func controlsView() -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(R.color.textFieldBorder.color)
            HStack(spacing: 12) {
                Button {
                    undoManager?.undo()
                } label: {
                    Constants.backwardImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .padding(10)
                        .foregroundColor(R.color.accentColor.color)
                }
                .disabled((undoManager?.canUndo ?? false) ? false : true)
                .opacity((undoManager?.canUndo ?? false) ? 1.0 : 0.3)

                Button {
                    undoManager?.redo()
                } label: {
                    Constants.forwardImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .padding(10)
                        .foregroundColor(R.color.accentColor.color)
                }
                .disabled((undoManager?.canRedo ?? false) ? false : true)
                .opacity((undoManager?.canRedo ?? false) ? 1.0 : 0.3)
                Spacer()
                if isContractInputActive {
                    Button {
                        isContractInputActive.toggle()
                    } label: {
                        Text(R.string.localizable.commonDone())
                            .font(.body.weight(.bold))
                            .padding(.trailing, 10)

                    }
                }

            }
            .padding(EdgeInsets(top: 0, leading: 6, bottom: 2, trailing: 6))
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
