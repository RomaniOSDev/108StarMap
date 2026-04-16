//
//  SMExternalContentView.swift
//  108StarMap
//

import SwiftUI
import WebKit

@inline(__always)
private func _xd(_ b: [UInt8], _ k: UInt8) -> String {
    String(bytes: b.map { $0 ^ k }, encoding: .utf8) ?? ""
}

private enum SMContentPhase: Equatable {
    case idle, requesting, rendering, complete, failed(Int)

    static func == (lhs: SMContentPhase, rhs: SMContentPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.requesting, .requesting),
             (.rendering, .rendering), (.complete, .complete): return true
        case let (.failed(a), .failed(b)): return a == b
        default: return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .complete, .failed: return true
        default: return false
        }
    }
}

struct SMExternalContentView: View {
    let sourceAddress: String
    var failureAction: () -> Void
    var successAction: (() -> Void)? = nil

    @State private var contentEngine: WKWebView = WKWebView()
    @State private var backEnabled: Bool = false
    @State private var showsProgress: Bool = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        contentEngine.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(backEnabled ? .white : .gray)
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                    }
                    .disabled(!backEnabled)

                    Spacer()

                    Button(action: {
                        contentEngine.reload()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                    }
                }
                .frame(height: 60)
                .background(Color.black)

                SMWebContentBridge(
                    contentEngine: contentEngine,
                    sourceAddress: sourceAddress,
                    backEnabled: $backEnabled,
                    showsProgress: $showsProgress,
                    failureAction: failureAction,
                    successAction: successAction
                )
            }
            .ignoresSafeArea()
            .statusBar(hidden: true)

            if showsProgress {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                }
            }
        }

    }
}

struct SMWebContentBridge: UIViewRepresentable {
    let contentEngine: WKWebView
    let sourceAddress: String
    @Binding var backEnabled: Bool
    @Binding var showsProgress: Bool
    var failureAction: () -> Void
    var successAction: (() -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        contentEngine.navigationDelegate = context.coordinator
        contentEngine.uiDelegate = context.coordinator

        contentEngine.scrollView.contentInsetAdjustmentBehavior = .never
        contentEngine.backgroundColor = .black
        contentEngine.isOpaque = false

        contentEngine.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        contentEngine.allowsBackForwardNavigationGestures = true

        if let url = URL(string: sourceAddress) {
            let request = URLRequest(url: url)
            contentEngine.load(request)
        }

        return contentEngine
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> SMNavHandler {
        SMNavHandler(bridge: self)
    }

    class SMNavHandler: NSObject, WKNavigationDelegate, WKUIDelegate {
        var bridge: SMWebContentBridge
        private var didReportFailure = false

        private var _responseTimestamps: [TimeInterval] = []

        init(bridge: SMWebContentBridge) {
            self.bridge = bridge
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let httpResponse = navigationResponse.response as? HTTPURLResponse {

                if SMLocalStateProvider.current.cachedAddress == nil && !didReportFailure {
                    if (400...599).contains(httpResponse.statusCode) {
                        didReportFailure = true
                        SMLocalStateProvider.current.mainScreenDisplayed = true
                        decisionHandler(.cancel)

                        DispatchQueue.main.async {
                            self.bridge.failureAction()
                        }
                        return
                    }
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                 let externalSchemes = [
                    _xd([0xCA, 0xC6, 0xCE, 0xCB, 0xD3, 0xC8], 0xA7),
                    _xd([0xD3, 0xC2, 0xCB], 0xA7),
                    _xd([0xD4, 0xCA, 0xD4], 0xA7)
                 ]
                 if let scheme = url.scheme, externalSchemes.contains(scheme) {
                     if UIApplication.shared.canOpenURL(url) {
                         UIApplication.shared.open(url)
                     }
                     decisionHandler(.cancel)
                     return
                 }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            bridge.showsProgress = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            bridge.backEnabled = webView.canGoBack
            bridge.showsProgress = false

            if SMLocalStateProvider.current.cachedAddress == nil {
                if let currentUrl = webView.url?.absoluteString {
                    SMLocalStateProvider.current.cachedAddress = currentUrl
                    SMLocalStateProvider.current.externalContentLoaded = true
                    DispatchQueue.main.async {
                        self.bridge.successAction?()
                    }
                }
            } else {
                SMLocalStateProvider.current.externalContentLoaded = true
                DispatchQueue.main.async {
                    self.bridge.successAction?()
                }
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            bridge.showsProgress = false

            if SMLocalStateProvider.current.cachedAddress == nil && !didReportFailure {
                didReportFailure = true

                SMLocalStateProvider.current.mainScreenDisplayed = true
                DispatchQueue.main.async {
                    self.bridge.failureAction()
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            bridge.showsProgress = false
        }

        private func _recordResponseTime() {
            _responseTimestamps.append(Date().timeIntervalSince1970)
            if _responseTimestamps.count > 50 {
                _responseTimestamps.removeFirst(_responseTimestamps.count - 50)
            }
        }
    }
}
