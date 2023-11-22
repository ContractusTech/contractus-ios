import Foundation
import ContractusAPI
import TweetNacl
import Web3Core
import Base58Swift

extension CommonAccount: Signer {
    func sign(data: Data) throws -> Data {
        switch blockchain {
        case .solana:
            return try NaclSign.signDetached(
                message: data,
                secretKey: privateKey)
        case .bsc:
            let hash = Utilities.hashPersonalMessage(data)!
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
            return Utilities.publicToAddressString(self.publicKeyData) ?? ""
        case .solana:
            return self.publicKey
        }
    }

    func encodeSignature(_ signature: Data) -> String {
        switch blockchain {
        case .solana:
            return Base58.base58Encode([UInt8](signature))
        case .bsc:
            return signature.toHexString().addHexPrefix()

        }
    }
}
