//
//  Pinger.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 12/14/16.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import Combine

import TcpCommands
import Shared

public enum PingStatus {
  case started
  case stopped(String?)
}

///  Pinger Actor implementation
///
///      generates "ping" messages every pingInterval second(s)
///      sends a PingStatus when stopped with an optional reason code
///
final public class Pinger {
  // ----------------------------------------------------------------------------
  // MARK: - Publishers
  
  public var pingPublisher = PassthroughSubject<PingStatus, Never>()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _lastPingRxTime: Date!
  private let _pingQ = DispatchQueue(label: "Radio.pingQ")
  private var _pingTimer: DispatchSourceTimer!
  private let _radio: Radio

  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(radio: Radio, pingInterval: Int = 1, pingTimeout: Double = 10) {
    _radio = radio
    _lastPingRxTime = Date(timeIntervalSinceNow: 0)
    startPinging(interval: pingInterval, timeout: pingTimeout)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  public func stopPinging(reason: String? = nil) {
    _pingTimer?.cancel()
    pingPublisher.send(.stopped(reason))
  }

  public func pingReply(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    _lastPingRxTime = Date()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  private func startPinging(interval: Int, timeout: Double) {
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
    let interval = Date().timeIntervalSince(_lastPingRxTime)
    if interval > timeout {
      // YES, stop the Pinger
      stopPinging(reason: "timeout")

    } else {
      // NO, ping again
      _radio.send("ping", replyTo: self.pingReply)
    }
  }
}
