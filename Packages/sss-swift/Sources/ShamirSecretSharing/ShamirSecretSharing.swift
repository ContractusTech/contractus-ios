import libsss


public enum CreateSharesError: Error {
    case invalidInputLength
    case invalidNParam
    case invalidKParam
}

public enum CombineSharesError: Error {
    case sharesArrayEmpty
    case badShareLength(Int)
}


func checkNK(n: Int, k: Int) throws {
    guard 1 <= n && n <= 255 else {
        throw CreateSharesError.invalidNParam
    }
    guard 1 <= k && k <= n else {
        throw CreateSharesError.invalidKParam
    }
}


func checkDataLen(data: [UInt8]) throws {
    guard data.count == sss_mlen else {
        throw CreateSharesError.invalidInputLength
    }
}


func checkKeyLen(key: [UInt8]) throws {
    guard key.count == 32 else {
        throw CreateSharesError.invalidInputLength
    }
}


func group(buf: UnsafeMutablePointer<UInt8>, group_size: Int, count: Int) -> [[UInt8]] {
    // Put a buffer of results in a Swift array
    var grouped: [[UInt8]] = []
    grouped.reserveCapacity(count)
    for i in 0..<count {
        let offset = i * group_size
        let cur = Array(UnsafeBufferPointer(start: buf + offset, count: group_size))
        grouped.append(cur)
    }
    return grouped
}


public func CreateShares(data: [UInt8], n: Int, k: Int) throws -> [[UInt8]] {
    try checkNK(n: n, k: k);
    try checkDataLen(data: data);

    // Call C API
    let share_len = MemoryLayout<sss_Share>.size
    let out = UnsafeMutablePointer<UInt8>.allocate(capacity: n * share_len)
    defer {
        out.deallocate()
    }
    out.withMemoryRebound(to: sss_Share.self, capacity: n) {
        let cOutShares = $0
        data.withUnsafeBufferPointer {
            (cData: UnsafeBufferPointer<UInt8>) -> Void in
            sss_create_shares(cOutShares, cData.baseAddress, UInt8(n), UInt8(k))
        }
    }

    return group(buf: out, group_size: share_len, count: n)
}


public func CombineShares(shares: [[UInt8]]) throws -> [UInt8]? {
    guard !shares.isEmpty else {
        throw CombineSharesError.sharesArrayEmpty
    }
    let k = shares.count

    // Unpack Swift array
    let share_len = MemoryLayout<sss_Share>.size
    var cShares = UnsafeMutablePointer<UInt8>.allocate(capacity: k * share_len)
    defer {
        cShares.deallocate()
    }
    for i in 0..<k {
        let share = shares[i]
        guard share.count == share_len else {
            throw CombineSharesError.badShareLength(i)
        }
        share.withUnsafeBufferPointer {
            (cShare: UnsafeBufferPointer<UInt8>) -> Void in
            let offset = i * share_len
            (cShares + offset).assign(from: cShare.baseAddress!, count: share_len)
        }
    }

    // Create data array
    var dataArray: [UInt8] = Array.init(repeating: 0, count: sss_mlen)

    // Call C API
    let retcode: Int = cShares.withMemoryRebound(to: sss_Share.self, capacity: k) {
        let cInShares = $0
        return dataArray.withUnsafeMutableBufferPointer {
            (cData: inout UnsafeMutableBufferPointer<UInt8>) -> Int in
            return Int(sss_combine_shares(cData.baseAddress, cInShares, UInt8(k)))
        }
    }
    return retcode == 0 ? dataArray : nil
}


public func CreateKeyshares(key: [UInt8], n: Int, k: Int) throws -> [[UInt8]] {
    try checkNK(n: n, k: k);
    try checkKeyLen(key: key);

    // Call C API
    let keyshare_len = MemoryLayout<sss_Keyshare>.size
    let out = UnsafeMutablePointer<UInt8>.allocate(capacity: n * keyshare_len)
    defer {
        out.deallocate()
    }
    out.withMemoryRebound(to: sss_Keyshare.self, capacity: n) {
        let cOutKeyshares = $0
        key.withUnsafeBufferPointer {
            (cData: UnsafeBufferPointer<UInt8>) -> Void in
            sss_create_keyshares(cOutKeyshares, cData.baseAddress, UInt8(n), UInt8(k))
        }
    }

    return group(buf: out, group_size: keyshare_len, count: n)
}


public func CombineKeyshares(keyshares: [[UInt8]]) throws -> [UInt8] {
    guard !keyshares.isEmpty else {
        throw CombineSharesError.sharesArrayEmpty
    }
    let k = keyshares.count

    // Unpack Swift array
    let keyshare_len = MemoryLayout<sss_Keyshare>.size
    var cKeyshares = UnsafeMutablePointer<UInt8>.allocate(capacity: k * keyshare_len)
    defer {
        cKeyshares.deallocate()
    }
    for i in 0..<k {
        let keyshare = keyshares[i]
        guard keyshare.count == keyshare_len else {
            throw CombineSharesError.badShareLength(i)
        }
        keyshare.withUnsafeBufferPointer {
            (cKeyshare: UnsafeBufferPointer<UInt8>) -> Void in
            let offset = i * keyshare_len
            (cKeyshares + offset).assign(from: cKeyshare.baseAddress!, count: keyshare_len)
        }
    }

    // Create data array
    var keyArray: [UInt8] = Array.init(repeating: 0, count: 32)

    // Call C API
    cKeyshares.withMemoryRebound(to: sss_Keyshare.self, capacity: k) {
        let cInKeyshares = $0
        keyArray.withUnsafeMutableBufferPointer {
            (cKey: inout UnsafeMutableBufferPointer<UInt8>) in
            sss_combine_keyshares(cKey.baseAddress, cInKeyshares, UInt8(k))
        }
    }
    return keyArray
}

/*
// TODO(dsprenkels) Currently, the test tool does not seem to work well
// with libraries that interface with C code. If the issues ever get fixed we
// should include test code. In the meantime, here are some examples:

let data = Array<UInt8>.init(repeating: 42, count: 64)
let shares = try? CreateShares(data: data, n: 5, k: 3)
print(shares ?? "CreateShares error")
var restored = try CombineShares(shares: shares!)
print(restored ?? "CombineShares error")

let key = Array<UInt8>.init(repeating: 42, count: 32)
let keyshares = try? CreateKeyshares(key: key, n: 5, k: 3)
print(keyshares ?? "CreateShares error")
restored = try CombineKeyshares(keyshares: keyshares!)
print(restored ?? "Convertsion error")
*/
