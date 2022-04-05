//
//  LoginViewTests.swift
//  
//
//  Created by Douglas Adams on 3/31/22.
//
import XCTest
import ComposableArchitecture

@testable import LoginView

class LoginViewTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLogin() {
      let store = TestStore(
        initialState: LoginState(),
        reducer: loginReducer,
        environment: LoginEnvironment()
//          queue: { self.scheduler.eraseToAnyScheduler() }
//        )
      )
      
//      store.send(.onAppear)
//      {
//        $0.discovery = Discovery.sharedInstance
//      }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
