//
//  WebView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.05.2023.
//

import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {

    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
