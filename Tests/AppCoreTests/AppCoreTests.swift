//
//  AppCoreTests.swift
//  
//
//  Created by Douglas Adams on 11/14/21.
//

import AppCore
import Discovery
import ComposableArchitecture
import XCTest

@testable import AppCore

class AppCoreTests: XCTestCase {
  
  func testIntegration() {
    let store = TestStore(
      initialState: .init(),
      reducer: appReducer,
      environment: AppEnvironment()
    )
    
    store.send(.pickerAction(.onAppear)) { state in
      print(state.pickerState)
    }
    store.receive(
      .pickerAction(.listenerStarted(Listener()))
    )
  }
}


