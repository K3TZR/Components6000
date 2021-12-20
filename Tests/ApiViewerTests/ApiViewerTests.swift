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
      initialState: .init(fontSize: 12, smartlinkEmail: "douglas.adams@me.com"),
      reducer: apiReducer,
      environment: ApiEnvironment(
        queue: { self.scheduler.eraseToAnyScheduler() }
      )
    )
    // StartStop (default is "START")
    store.send(.buttonTapped(.startStop)) {
      $0.pickerState = PickerState()
    }
    store.send(.buttonTapped(.startStop)) {
      $0.pickerState = nil
    }
    // isGui (default is "ON")
    store.send(.buttonTapped(.isGui)) {
      $0.isGui = false
    }
    store.send(.buttonTapped(.isGui)) {
      $0.isGui = true
    }
    // showTimes
    store.send(.buttonTapped(.showTimes)) {
      $0.showTimes = true
    }
    store.send(.buttonTapped(.showTimes)) {
      $0.showTimes = false
    }
    // showPings
    store.send(.buttonTapped(.showPings)) {
      $0.showPings = true
    }
    store.send(.buttonTapped(.showPings)) {
      $0.showPings = false
    }
    // showReplies
    store.send(.buttonTapped(.showReplies)) {
      $0.showReplies = true
    }
    store.send(.buttonTapped(.showReplies)) {
      $0.showReplies = false
    }
    // showButtons
    store.send(.buttonTapped(.showButtons)) {
      $0.showButtons = true
    }
    store.send(.buttonTapped(.showButtons)) {
      $0.showButtons = false
    }
    // clearOnConnect
    store.send(.buttonTapped(.clearOnConnect)) {
      $0.clearOnConnect = true
    }
    store.send(.buttonTapped(.clearOnConnect)) {
      $0.clearOnConnect = false
    }
    // clearOnDisconnect
    store.send(.buttonTapped(.clearOnDisconnect)) {
      $0.clearOnDisconnect = true
    }
    store.send(.buttonTapped(.clearOnDisconnect)) {
      $0.clearOnDisconnect = false
    }
    // clearOnSend
    store.send(.buttonTapped(.clearOnSend)) {
      $0.clearOnSend = true
    }
    store.send(.buttonTapped(.clearOnSend)) {
      $0.clearOnSend = false
    }
    // Command to send
    store.send(.commandToSendChanged("info")) {
      $0.commandToSend = "info"
    }
    store.send(.commandToSendChanged("")) {
      $0.commandToSend = ""
    }
    store.send(.buttonTapped(.send))
    // font size
    store.send(.fontSizeChanged(8)) {
      $0.fontSize = 8
    }
    store.send(.fontSizeChanged(12)) {
      $0.fontSize = 12
    }
    
    // currently unimplemented
    store.send(.buttonTapped(.smartlinkLogin))
    store.send(.buttonTapped(.status))
    store.send(.buttonTapped(.clearNow))
  }
}
