//
//  WebView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.05.2023.
//

import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {
    private let webView = WKWebView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var request: URLRequest
    private var failUrl: URL?
    private var successUrl: URL?
    private var closeHandler: ((Bool) -> Void)?

    init(url: URL) {
        self.request = .init(url: url)
    }

    init(request: URLRequest, successUrl: URL? = nil, failUrl: URL? = nil, closeHandler: @escaping (Bool) -> Void) {
        self.request = request
        self.successUrl = successUrl
        self.failUrl = failUrl
        self.closeHandler = closeHandler
    }

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

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .other {
                if parent.failUrl == navigationAction.request.url {
                    parent.closeHandler?(false)
                    decisionHandler(.cancel)
                    return
                }

                if parent.successUrl == navigationAction.request.url {
                    parent.closeHandler?(true)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}
