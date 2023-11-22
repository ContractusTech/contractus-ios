import Foundation
import ContractusAPI
import TweetNacl
import Web3Core

extension CommonAccount: Signer {
    func sign(data: Data) throws -> Data {
        switch blockchain {
        case .solana:
            return try NaclSign.signDetached(
                message: data,
                secretKey: privateKey)
        case .bsc:
            let hash = data.sha3(.keccak256)
            let (compressedSignature, _) = SECP256K1.signForRecovery(
                hash: hash,
                privateKey: privateKey,
                useExtraEntropy: false)

            guard let compressedSignature = compressedSignature else { throw SignerError.emptySignature }
            return compressedSignature

        }
    }

    func getPublicKey() -> String {
        switch blockchain {
        case .bsc:
            return Utilities.privateToPublic(self.privateKey)?.toHexString() ?? ""
        case .solana:
            return self.publicKey
        }
    }
}
