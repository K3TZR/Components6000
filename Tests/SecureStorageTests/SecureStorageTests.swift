//
//  SecureStorageTests.swift
//  Components6000/SecureStorageTests
//
//  Created by Douglas Adams on 12/2/21.
//

import XCTest
import SecureStorage

@testable import SecureStorage

class SecureStorageTests: XCTestCase {
  let account = "somebody@someplace.com"
  
  let secureStore = SecureStore(service: "SecureStorageTests.testKeys")
  
  func testStorage() {

    XCTAssert( secureStore.set(account: account, data: "a key value") == true )
                   
    XCTAssert( secureStore.get(account: account) == "a key value")
    
    XCTAssert( secureStore.delete(account: account) == true )
    
    XCTAssert( secureStore.get(account: account) == nil)

  }
}

