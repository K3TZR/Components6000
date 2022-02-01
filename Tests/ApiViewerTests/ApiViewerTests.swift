//
//  ApiViewerTests.swift
//  Components6000/ApiViewerTests
//
//  Created by Douglas Adams on 11/14/21.
//

import XCTest
import ComposableArchitecture
import ApiViewer
import Picker

@testable import ApiViewer

class ApiViewerTests: XCTestCase {
  let scheduler = DispatchQueue.test
  
  func testButtons() {
    let store = TestStore(
      initialState: .init(domain: "net.k3tzr", appName: "ApiViewerTests"),
      reducer: apiReducer,
      environment: ApiEnvironment(
        queue: { self.scheduler.eraseToAnyScheduler() }
      )
    )
    // StartStop (default is "START")
    store.send(.startStopButton) {
      $0.pickerState = PickerState()
    }
    store.send(.startStopButton) {
      $0.pickerState = nil
    }
    // isGui (default is "ON")
    store.send(.toggleButton(\.isGui)) {
      $0.isGui = false
    }
    store.send(.toggleButton(\.isGui)) {
      $0.isGui = true
    }
    // showTimes
    store.send(.toggleButton(\.showTimes)) {
      $0.showTimes = true
    }
    store.send(.toggleButton(\.showTimes)) {
      $0.showTimes = false
    }
    // showPings
    store.send(.toggleButton(\.showPings)) {
      $0.showPings = true
    }
    store.send(.toggleButton(\.showPings)) {
      $0.showPings = false
    }
    // clearOnConnect
    store.send(.toggleButton(\.clearOnConnect)) {
      $0.clearOnConnect = true
    }
    store.send(.toggleButton(\.clearOnConnect)) {
      $0.clearOnConnect = false
    }
    // clearOnDisconnect
    store.send(.toggleButton(\.clearOnDisconnect)) {
      $0.clearOnDisconnect = true
    }
    store.send(.toggleButton(\.clearOnDisconnect)) {
      $0.clearOnDisconnect = false
    }
    // clearOnSend
    store.send(.toggleButton(\.clearOnSend)) {
      $0.clearOnSend = true
    }
    store.send(.toggleButton(\.clearOnSend)) {
      $0.clearOnSend = false
    }
    // Command to send
    store.send(.commandTextField("info")) {
      $0.commandToSend = "info"
    }
    store.send(.commandTextField("")) {
      $0.commandToSend = ""
    }
    store.send(.sendButton)

    // font size
    store.send(.fontSizeStepper(8)) {
      $0.fontSize = 8
    }
    store.send(.fontSizeStepper(12)) {
      $0.fontSize = 12
    }
    
    // currently unimplemented
    store.send(.clearDefaultButton)
    store.send(.clearNowButton)
  }
}
