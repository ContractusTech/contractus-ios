//
//  WebView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.05.2023.
//

import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {
    let webView = WKWebView()
    let loadingIndicator = UIActivityIndicatorView(style: .medium)
    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        self.webView.navigationDelegate = context.coordinator

        self.webView.isOpaque = false
        self.webView.backgroundColor = R.color.mainBackground()
        self.webView.scrollView.backgroundColor = R.color.mainBackground()

        self.loadingIndicator.hidesWhenStopped = true
        self.loadingIndicator.startAnimating()
        self.loadingIndicator.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 50)
        self.webView.addSubview(loadingIndicator)
        return self.webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.parent.loadingIndicator.stopAnimating()
        }
    }
}
