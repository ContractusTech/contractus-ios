import Foundation

public struct DeviceMessage: Decodable {
    let message: String
    let expired: Date
}
