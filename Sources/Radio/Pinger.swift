//
//  Pinger.swift
//  CommonCode
//
//  Created by Douglas Adams on 12/14/16.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import TcpCommands
import Shared

///  Pinger Class implementation
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
  private var _responseCount = 0
  private var _command: TcpCommand

  private let kPingInterval    = 1
  private let kResponseCount = 2
  private let kTimeoutInterval = 30.0

  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(radio: Radio, command: TcpCommand) {
    _radio = radio
    _command = command
    startPinging()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  public func stopPinging() {
    _pingTimer?.cancel()
    _responseCount = 0
    _log("Pinger: stopped", .debug, #function, #file, #line)
  }

  public func pingReply(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    _responseCount += 1
    // notification can be used to signal that the Radio is now fully initialized
//    if _responseCount == kResponseCount { NC.post(.tcpPingResponse, object: nil) }

    _pingQ.async { [weak self] in
      // save the time of the Response
      self?._lastPingRxTime = Date()
    }
  }

  public func startPinging() {
    _log("Pinger: started", .debug, #function, #file, #line)

    // tell the Radio to expect pings
    _radio.send("keepalive enable")

    // fake the first response
    _lastPingRxTime = Date(timeIntervalSinceNow: 0)

    // create the timer's dispatch source
    _pingTimer = DispatchSource.makeTimerSource(queue: _pingQ)

    // Setup the timer and inform observers
    _pingTimer.schedule(deadline: DispatchTime.now(), repeating: .seconds(kPingInterval))
//    NC.post(.tcpPingStarted, object: nil)

    // set the event handler
    _pingTimer.setEventHandler { [ unowned self] in
      // get current datetime
      let now = Date()

      // has it been too long since the last response?
      if now.timeIntervalSince(self._lastPingRxTime) > kTimeoutInterval {
        // YES, timeout, inform observers
//        NC.post(.tcpPingTimeout, object: nil)

        // stop the Pinger
        let interval = String(format: "%02.1f", now.timeIntervalSince(self._lastPingRxTime))
        _log("Pinger: timeout, interval = \(interval)", .debug, #function, #file, #line)
        self.stopPinging()

      } else {
        // NO, send another Ping
        _radio.send("ping", replyTo: self.pingReply)
      }
    }
    // start the timer
    _pingTimer.resume()
  }
}
