import SolanaSwift
import ContractusAPI
import Web3Core

extension Blockchain {
    func isValidPublicKey(string: String) -> Bool {
        switch self {
        case .solana:
            return string.utf8.count == 32 && PublicKey.isOnCurve(publicKey: string) == 1
        case .bsc:
            // TODO: - Added validate
            return true
        }
    }
}
