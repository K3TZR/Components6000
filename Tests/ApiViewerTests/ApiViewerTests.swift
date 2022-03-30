//
//  ApiViewerTests.swift
//  Components6000/ApiViewerTests
//
//  Created by Douglas Adams on 11/14/21.
//

import XCTest
import ComposableArchitecture

import ApiViewer
import Discovery
import Login
import Picker
import XCGWrapper
import Shared

@testable import ApiViewer

class ApiViewerTests: XCTestCase {
  let scheduler = DispatchQueue.test
  
  func testButtons() {
    let store = TestStore(
      initialState: .init(),
      reducer: apiReducer,
      environment: ApiEnvironment(
        queue: { self.scheduler.eraseToAnyScheduler() }
      )
    )
    
    store.send(.onAppear) {
      $0.discovery = Discovery.sharedInstance
    }
    scheduler.advance()
    
    store.receive( .finishInitialization ) {
      $0.loginState = LoginState(heading: "Smartlink Login required", email: $0.smartlinkEmail)
    }

    scheduler.advance()
    store.send(.loginAction(.loginButton(LoginResult("myUser@some.com", pwd: "myPwd")))) {
      $0.loginState = nil
      $0.smartlinkEmail = "myUser@some.com"
      $0.alert = AlertState(title: TextState("Smartlink login failed"))
    }
    
    store.send(.toggle(\.isGui)) {                // isGui (default is "ON")
      $0.isGui = false
    }
    store.send(.toggle(\.isGui)) {
      $0.isGui = true
    }
    store.send(.toggle(\.showPings)) {            // showPings
      $0.showPings = true
    }
    store.send(.toggle(\.showPings)) {
      $0.showPings = false
    }
    store.send(.toggle(\.showTimes)) {            // showTimes
      $0.showTimes = true
    }
    store.send(.toggle(\.showTimes)) {
      $0.showTimes = false
    }
    store.send(.toggle(\.clearOnConnect)) {       // clearOnConnect
      $0.clearOnConnect = true
    }
    store.send(.toggle(\.clearOnConnect)) {
      $0.clearOnConnect = false
    }
    store.send(.toggle(\.clearOnDisconnect)) {    // clearOnDisconnect
      $0.clearOnDisconnect = true
    }
    store.send(.toggle(\.clearOnDisconnect)) {
      $0.clearOnDisconnect = false
    }
    store.send(.toggle(\.clearOnSend)) {          // clearOnSend
      $0.clearOnSend = true
    }
    store.send(.toggle(\.clearOnSend)) {
      $0.clearOnSend = false
    }
    store.send(.toggle(\.reverseLog)) {           // reverseLog
      $0.reverseLog = true
    }
    store.send(.toggle(\.reverseLog)) {
      $0.reverseLog = false
    }
    store.send(.fontSizeStepper(8)) {                   // font size
      $0.fontSize = 8
    }
    store.send(.fontSizeStepper(12)) {
      $0.fontSize = 12
    }
    store.send(.commandTextField("info")) {             // Command to send
      $0.commandToSend = "info"
    }
    store.send(.commandTextField("")) {
      $0.commandToSend = ""
    }
    store.send(.forceLoginButton) {                     // Force Wan login
      $0.forceWanLogin = true
    }
    scheduler.advance()
    store.receive( .finishInitialization) {
      $0.loginState = LoginState(heading: "Smartlink Login required", email: $0.smartlinkEmail)
    }
    store.send(.forceLoginButton) {
      $0.forceWanLogin = false
    }
    
    // Tcp messages
    let message1 = TcpMessage(direction: .received, text: "This is a received message", color: .red, timeInterval: 1.0)
    store.send(.tcpMessageSentOrReceived(message1)) {
      $0.messages = [message1]
      $0.filteredMessages = [message1]
      $0.messages[id: message1.id] = message1
      $0.filteredMessages[id: message1.id] = message1
    }
    let message2 = TcpMessage(direction: .sent, text: "This is a sent message", color: .red, timeInterval: 1.0)
    store.send(.tcpMessageSentOrReceived(message2)) {
      $0.messages = [message1, message2]
      $0.filteredMessages = [message1, message2]
      $0.messages[id: message2.id] = message2
      $0.filteredMessages[id: message2.id] = message2
    }
    store.send(.clearNowButton) {                       // Clear Now
      $0.messages = []
      $0.filteredMessages = []
    }
    store.send(.startStopButton) {                      // Start / Stop
      $0.pickerState = PickerState(connectionType: $0.isGui ? .gui : .nonGui)
    }

    store.send( .cancelEffects )

  }
}
