//
//  DocumentPickerView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 09.11.2022.
//

import UniformTypeIdentifiers.UTType
import SwiftUI

struct DocumentPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    let types: [UTType]
    var action: ((Data, URL) -> Void)?

    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPickerView>) -> UIDocumentPickerViewController {
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        docPicker.delegate = context.coordinator
        return docPicker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: UIViewControllerRepresentableContext<DocumentPickerView>) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {

        var parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedFile: URL = urls.first else { return }
            
            if selectedFile.startAccessingSecurityScopedResource(), let data = try? Data(contentsOf: selectedFile) {
                parent.action?(data, selectedFile)
                defer { selectedFile.stopAccessingSecurityScopedResource() }
            } else {

            }
        }

    }
}
