import SolanaSwift
import ContractusAPI
import Web3Core

extension Blockchain {
    func isValidPublicKey(string: String) -> Bool {
        switch self {
        case .solana:
            return string.utf8.count >= 32 && PublicKey.isOnCurve(publicKey: string) == 1
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
