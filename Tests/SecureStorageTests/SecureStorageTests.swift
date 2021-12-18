//
//  SecureStorageTests.swift
//
//
//  Created by Douglas Adams on 12/2/21.
//

import XCTest
import SecureStorage

@testable import SecureStorage

class SecureStorageTests: XCTestCase {
  let account = "somebody@someplace.com"
  
  let tokenStore = TokenStore(service: "TestSecureStorage.testTokens")
  
  func testStorage() {

    XCTAssert( tokenStore.set(account: account, data: "a key value") == true )
                   
    XCTAssert( tokenStore.get(account: account) == "a key value")
    
    XCTAssert( tokenStore.delete(account: account) == true )
    
    XCTAssert( tokenStore.get(account: account) == nil)

  }
}

