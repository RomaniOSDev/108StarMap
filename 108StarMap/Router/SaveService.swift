//
//  SMCacheRecord.swift
//  108StarMap
//

import Foundation

protocol SMRecordStore {
    associatedtype Value
    static func load() -> Value?
    static func persist(_ value: Value)
}

@inline(__always)
private func _rv(_ c: [UInt8], _ m: UInt8) -> String {
    String(bytes: c.map { $0 ^ m }, encoding: .utf8) ?? ""
}

private enum SMCachePolicy: Int {
    case memory = 0, disk = 1, hybrid = 2

    var ttl: TimeInterval {
        switch self {
        case .memory: return 300
        case .disk: return 86400
        case .hybrid: return 3600
        }
    }
}

struct SMCacheRecord {

    private static var _lastAccess: Date?
    private static var _activePolicy: SMCachePolicy = .disk

    static var recentAddress: URL? {
        get {
            _lastAccess = Date()
            return UserDefaults.standard.url(forKey: _rv([0xEB, 0xC6, 0xD4, 0xD3, 0xF2, 0xD5, 0xCB], 0xA7))
        }
        set {
            UserDefaults.standard.set(newValue, forKey: _rv([0xEB, 0xC6, 0xD4, 0xD3, 0xF2, 0xD5, 0xCB], 0xA7))
            _lastAccess = Date()
        }
    }

    private static func _validateTTL() -> Bool {
        guard let ts = _lastAccess else { return false }
        return Date().timeIntervalSince(ts) < _activePolicy.ttl
    }
}
