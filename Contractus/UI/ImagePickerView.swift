//
//  ImagePickerView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 07.08.2022.
//


import SwiftUI
import UIKit

struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var action: ((UIImage, URL) -> Void)?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIImagePickerController {

        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePickerView>) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        var parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let imgName = UUID().uuidString + ".png"
            let documentDirectory = NSTemporaryDirectory()
            let url = info[UIImagePickerController.InfoKey.imageURL] as? URL ?? URL(string: documentDirectory.appending(imgName))
            
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage, let url = url {
                parent.action?(image, url)
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

    }
}
