import SwiftUI

struct UndoTextView: UIViewRepresentable {

    @Binding var content: String
    @Binding var undoManager: UndoManager?

    func makeUIView(context: Context) -> UITextView {
        let uiTextView = UITextView()
        uiTextView.delegate = context.coordinator
        uiTextView.text = content
        uiTextView.font = UIFont.preferredFont(forTextStyle: .body)

        DispatchQueue.main.async {
            self.undoManager = uiTextView.undoManager
        }

        return uiTextView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {

        var parent: UndoTextView

        init(_ parent: UndoTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.content = textView.text
        }
    }
}

