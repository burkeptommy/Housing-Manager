import Foundation

final class CacheManager {
    static let shared = CacheManager()
    private let cache = NSCache<NSString, NSData>()

    private init() {
        cache.countLimit = 100
    }

    func set(_ data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString)
    }

    func get(forKey key: String) -> Data? {
        cache.object(forKey: key as NSString) as Data?
    }

    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func clearAll() {
        cache.removeAllObjects()
    }
}
