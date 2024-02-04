import SolanaSwift
import ContractusAPI
import Web3Core

extension Blockchain {
    func isValidPublicKey(string: String) -> Bool {
        switch self {
        case .solana:
            let data = Base58.decode(string)
            guard !data.isEmpty else { return false }
            return PublicKey.isOnCurve(publicKeyBytes: Data(data)) == 1
        case .bsc:
            return EthereumAddress(string) != nil
        }
    }

    var wrapTokenCode: String {
        switch self {
        case.bsc:
            return "WBNB"
        case .solana:
            return "WSOL"
        }
    }
}
