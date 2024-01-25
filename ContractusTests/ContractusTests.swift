//
//  ContractusTests.swift
//  ContractusTests
//
//  Created by Simon Hudishkin on 24.07.2022.
//

import XCTest
import SolanaSwift
@testable import Contractus

class ContractusTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSerializeTx() throws {
        let base64String = "AwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMCCBEmOcVnyCCnPB1jxt4OpkWoARi5eor/JWT3o34YkUo1gyYJwexYvT8Jg8Rnm+kYa1gvfRFUGoaotOU18bU3ECHIh3EL3+PICVPY/e2Zts0a0prItqjq7AUGqessPoY4BU9G2ikf/4gWcSHd8j2Nk2X1YCXhq+elr3r6dg0ZcFk1EJ1I+I+1Tsr7Dk6GVl0f8z2MeC8lsE/pdL2ily7EwP1xn/Sfrb6wsnRefK4K8uuvXmS3LhPlBgX3Gr0PpCad8CC8+p7B4GjnaYr9zhsJA8wxnEczVtLOew8ZxC+E2O/Ltd/8i+NFPweW/5fhoblvluSDNIzXIbPJTvW6ljokSkB86N7Nbv0id38dvWXlfvkZhBGG1+zb8lF/7lqLNe9AYksAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFLH19JlHlmDg6bRBCJQIjTb0bT/ylxJc2RQZ+4TUnFfjJclj04kifG7PRApFI4NgwtaE5na/xCEBI572Nvp+FmlcRR2jAfhttod4Ky011Oc7N2YzvZJ8yEyxneBIi0pV7H3IpHtWSfzTMwjbu7fS2JyqSlLNp26GYeih63jZsBeBpuIV/6rgYT7aH9jRhjANdrEOdwa6ztVmKDwAAAAAAEGp9UXGSxWjuCKhF9z0peIzwNcMUWyGrNE2AYuqUAAAAbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpP0CkBkKDOeythv+ch6ujDNog3F/LkiedoCOQdYWcAxgCCQMDDwAEBAAAAAoZAgEAAA4ODg4NDAcICAYECAYEBAgEBQkQCzWvr20fDZib7Svx27WJ70+tq13TiW4jU0VAQg8AAAAAAPsGWwEAAAAAAUwzKWYAAAAAAAAAAA=="

        var tx = try Transaction.from(data: Data(base64Encoded: base64String)!)
        let serializedString = (try tx.serialize(requiredAllSignatures: false)).base64EncodedString()
        assert(base64String == serializedString)
    }
}
