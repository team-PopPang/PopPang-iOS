//
//  NotificationView.swift
//  PopPang
//
//  Created by 김동현 on 10/30/25.
//

import SwiftUI
import WebKit

struct NotificationView: View {
    var body: some View {
        WebView(url: URL(string: Constants.URL.notification))
    }
}

// MARK: - WebView Wrapper
struct WebView: UIViewRepresentable {
    let url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = context.coordinator
        if let url = url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // URL이 변경되면 새로 로드
        if let url = url {
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> WebCoordinator {
        Coordinator()
    }

    class WebCoordinator: NSObject, WKNavigationDelegate {}
}


#Preview {
    NotificationView()
}

