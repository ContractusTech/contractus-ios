import XCTest
@testable import ContractusAPI

final class ContractusAPITests: XCTestCase {
    func testCurrencyFormatToString() throws {
        XCTAssertEqual(Currency(code: "SOL", name: "Solana", decimal: 9).format(amount: 1000000000), "SOL 1.00")
        XCTAssertEqual(Currency(code: "SOL", name: "Solana", decimal: 9).format(amount: 1000000001), "SOL 1.000000001")
        XCTAssertEqual(Currency(code: "USDC", name: "USD Coin", decimals: 6).format(amount: 1000000001), "USDC 1,000.000001")
        XCTAssertEqual(Currency(code: "USDC", name: "USD Coin", decimal: 0).format(amount: 1000000001), "USDC 1,000,000,001")
    }

    func testCurrencyFormatToInt() throws {
        XCTAssertEqual(Currency(code: "USDC", name: "USD Coin", decimals: 6).format(string: "1,000.000001"), 1000000001)
        XCTAssertEqual(Currency(code: "SOL", name: "Solana", decimal: 9).format(string: "1.000000001"), 1000000001)
        XCTAssertEqual(Currency(code: "XXX", name: "XXX", decimal: 0).format(string: "1.000000001"), 1)
        XCTAssertEqual(Currency(code: "XXX", name: "XXX", decimal: 0).format(string: "1000000001"), 1000000001)

        let amount = Currency(code: "USDC", name: "USD Coin", decimals: 6).format(string: "1,000.0000010000")
        XCTAssertEqual(Currency(code: "USDC", name: "USD Coin", decimals: 6).format(amount: amount!), "USDC 1,000.000001")
    }
}
