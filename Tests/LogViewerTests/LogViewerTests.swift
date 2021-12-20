//
//  LogViewerTests.swift
//  Components6000/LogViewerTests
//
//  Created by Douglas Adams on 12/2/21.
//

import XCTest
import ComposableArchitecture
import LogViewer

@testable import LogViewer

class LogViewerTests: XCTestCase {
  
  func testButtons() {
    let store = TestStore(
      initialState: .init(fontSize: 12),
      reducer: logReducer,
      environment: LogEnvironment()
    )
    
    store.send(.timestampsButton) {
      $0.showTimestamps.toggle()
    }
    store.send(.fontSize(10)) {
      $0.fontSize = 10
    }
    store.send(.fontSize(12)) {
      $0.fontSize = 12
    }
    store.send(.filterBy(.includes)) {
      $0.filterBy = .includes
    }
    store.send(.filterBy(.excludes)) {
      $0.filterBy = .excludes
    }
    store.send(.logLevel(.debug)) {
      $0.logLevel = .debug
    }
    store.send(.logLevel(.info)) {
      $0.logLevel = .info
    }
    store.send(.logLevel(.warning)) {
      $0.logLevel = .warning
    }
    store.send(.logLevel(.error)) {
      $0.logLevel = .error
    }
    store.send(.filterByText("some filter")) {
      $0.filterByText = "some filter"
    }
    
    store.send(.clearButton) { _ in
      // TODO: ???
    }
    store.send(.refreshButton) { _ in
      // TODO: ???
    }
    store.send(.saveButton) { _ in
      // TODO: ???
    }
    store.send(.loadButton) { _ in
      // TODO: ???
    }
    store.send(.emailButton) { _ in
      // TODO: ???
    }
    store.send(.apiViewButton) { _ in
      // TODO: ???
    }
  }
}

