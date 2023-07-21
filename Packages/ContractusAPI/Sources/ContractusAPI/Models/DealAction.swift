import Foundation

public struct DealAction: Decodable {

    public enum Action: String, Decodable {
        case sign = "SIGN", cancelSign = "CANCEL_SIGN", finish = "FINISH", cancel = "CANCEL"
    }

    public let signedByChecker: Bool?
    public let signedByContractor: Bool?
    public let signedByOwner: Bool?

    public let actions: [Action]

    public init(actions: [Action], signedByChecker: Bool? = nil, signedByContractor: Bool? = nil, signedByOwner: Bool? = nil) {
        self.signedByChecker = signedByChecker
        self.signedByContractor = signedByContractor
        self.signedByOwner = signedByOwner
        self.actions = actions
    }
}
