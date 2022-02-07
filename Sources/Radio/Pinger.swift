//
//  Pinger.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 12/14/16.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import TcpCommands
import Shared

///  Pinger Actor implementation
///
///      generates "ping" messages every kPingInterval second(s)
///      if no reply is received after kTimeoutInterval
///      sends a .tcpPingTimeout Notification
///
final public class Pinger {
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _lastPingRxTime: Date!
  private let _log = LogProxy.sharedInstance.log
  private let _pingQ = DispatchQueue(label: "Radio.pingQ")
  private var _pingTimer: DispatchSourceTimer!
  private let _radio: Radio
  private var _command: Tcp

  private let kPingInterval = 1
  private let kTimeoutInterval = 10.0

  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(radio: Radio, command: Tcp, pingInterval: Int = 1, pingTimeout: Double = 10) {
    _radio = radio
    _command = command
    _lastPingRxTime = Date(timeIntervalSinceNow: 0)
    startPinging(interval: pingInterval, timeout: pingTimeout)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  public func stopPinging() {
    _pingTimer?.cancel()
    _log("Pinger: stopped", .debug, #function, #file, #line)
  }

  public func pingReply(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    _lastPingRxTime = Date()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  private func startPinging(interval: Int, timeout: Double) {
    _log("Pinger: started pinging", .debug, #function, #file, #line)

    // tell the Radio to expect pings
    _radio.send("keepalive enable")

    // create the timer's dispatch source
    _pingTimer = DispatchSource.makeTimerSource(queue: _pingQ)

    // Setup the timer
    _pingTimer.schedule(deadline: DispatchTime.now(), repeating: .seconds(interval))

    // set the event handler
    _pingTimer.setEventHandler(handler: { self.timerHandler(timeout: timeout) })

    // start the timer
    _pingTimer.resume()
  }

  private func timerHandler(timeout: Double) {
    // has it been too long since the last response?
    if Date().timeIntervalSince(_lastPingRxTime) > timeout {
      // YES, stop the Pinger
      _log("Pinger: timeout", .debug, #function, #file, #line)
      stopPinging()

    } else {
      // NO, ping again
      _radio.send("ping", replyTo: self.pingReply)
    }
  }
}
