//
//  QuickLookView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 22.11.2022.
//

import UIKit
import SwiftUI
import QuickLook
import SafariServices

struct QuickLookView: UIViewControllerRepresentable {

    var url: URL
    var onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func updateUIViewController(_ viewController: UINavigationController, context: UIViewControllerRepresentableContext<QuickLookView>) {
        if let controller = viewController.topViewController as? QLPreviewController {
            controller.reloadData()
        }
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.currentPreviewItemIndex = 0
        controller.reloadData()
        return UINavigationController(rootViewController: controller)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {

        var parent: QuickLookView

        init(_ parent: QuickLookView) {
            self.parent = parent
            super.init()
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return self.parent.url as QLPreviewItem
        }
    }
}

