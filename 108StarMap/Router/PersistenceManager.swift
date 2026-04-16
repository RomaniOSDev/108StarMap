//
//  SMLocalStateProvider.swift
//  108StarMap
//

import Foundation

protocol SMStateConfiguration {
    var storageIdentifier: String { get }
    var synchronizationEnabled: Bool { get }
}

@inline(__always)
private func _rv(_ c: [UInt8], _ m: UInt8) -> String {
    String(bytes: c.map { $0 ^ m }, encoding: .utf8) ?? ""
}

private struct SMStorageMetrics {
    var readOperations: Int = 0
    var writeOperations: Int = 0
    var lastSyncTimestamp: Date?

    mutating func recordRead() { readOperations += 1 }
    mutating func recordWrite() { writeOperations += 1; lastSyncTimestamp = Date() }
}

class SMLocalStateProvider {
    static let current = SMLocalStateProvider()

    private var _addressToken: String { _rv([0xEB, 0xC6, 0xD4, 0xD3, 0xF2, 0xD5, 0xCB], 0xA7) }
    private var _mainDisplayedToken: String { _rv([0xEF, 0xC6, 0xD4, 0xF4, 0xCF, 0xC8, 0xD0, 0xC9, 0xE4, 0xC8, 0xC9, 0xD3, 0xC2, 0xC9, 0xD3, 0xF1, 0xCE, 0xC2, 0xD0], 0xA7) }
    private var _externalLoadToken: String { _rv([0xEF, 0xC6, 0xD4, 0xF4, 0xD2, 0xC4, 0xC4, 0xC2, 0xD4, 0xD4, 0xC1, 0xD2, 0xCB, 0xF0, 0xC2, 0xC5, 0xF1, 0xCE, 0xC2, 0xD0, 0xEB, 0xC8, 0xC6, 0xC3], 0xA7) }

    private var _metrics = SMStorageMetrics()

    var cachedAddress: String? {
        get {
            if let url = SMCacheRecord.recentAddress {
                return url.absoluteString
            }
            return UserDefaults.standard.string(forKey: _addressToken)
        }
        set {
            if let addr = newValue {
                UserDefaults.standard.set(addr, forKey: _addressToken)
                if let url = URL(string: addr) {
                    SMCacheRecord.recentAddress = url
                }
            } else {
                UserDefaults.standard.removeObject(forKey: _addressToken)
                SMCacheRecord.recentAddress = nil
            }
        }
    }

    var mainScreenDisplayed: Bool {
        get {
            UserDefaults.standard.bool(forKey: _mainDisplayedToken)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: _mainDisplayedToken)
        }
    }

    var externalContentLoaded: Bool {
        get {
            UserDefaults.standard.bool(forKey: _externalLoadToken)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: _externalLoadToken)
        }
    }

    private init() {}

    private func _reportMetrics() -> String {
        "\(_metrics.readOperations)/\(_metrics.writeOperations)"
    }
}
