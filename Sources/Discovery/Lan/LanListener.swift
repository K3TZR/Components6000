//
//  LanListener.swift
//  Components6000/Discovery/Lan
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import Combine

import CocoaAsyncSocket
import Shared

public enum LanListenerError: Error {
  case kSocketError
  case kReceivingError
}

/// Listener implementation
///
///      listens for the udp broadcasts announcing the presence
///      of a Flex-6000 Radio, publishes changes
///
final class LanListener: NSObject, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public private(set) var isListening: Bool = false

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  weak var _discovery: Discovery?

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _cancellables = Set<AnyCancellable>()
  private let _formatter = DateFormatter()
  private let _udpQ = DispatchQueue(label: "DiscoveryListener" + ".udpQ")
  private var _udpSocket: GCDAsyncUdpSocket!

  let _log = LogProxy.sharedInstance.log

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(_ discovery: Discovery, port: UInt16 = 4992) {
    super.init()
    _discovery = discovery
    
    _formatter.timeZone = .current
    _formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    // create a Udp socket and set options
    _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: _udpQ )
    _udpSocket.setPreferIPv4()
    _udpSocket.setIPv6Enabled(false)
    
    try! _udpSocket.enableReusePort(true)
    try! _udpSocket.bind(toPort: port)
    _log("Discovery: Lan Listener UDP Socket initialized", .debug, #function, #file, #line)
  }

  func start(checkInterval: TimeInterval = 1.0, timeout: TimeInterval = 10.0) throws {
    do {
      try _udpSocket.beginReceiving()
      DispatchQueue.main.async { self.isListening = true }
      _log("Discovery: Lan Listener is listening", .debug, #function, #file, #line)
      
      // setup a timer to watch for Radio timeouts
      Timer.publish(every: checkInterval, on: .main, in: .default)
        .autoconnect()
        .sink { [self] now in
          remove(condition: { $0.source == .local && abs($0.lastSeen.timeIntervalSince(now)) > timeout } )
        }
        .store(in: &_cancellables)

    } catch {
      throw LanListenerError.kReceivingError
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// stop the listener
  func stop() {
    _cancellables = Set<AnyCancellable>()
    _udpSocket?.close()
    isListening = false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Remove a packet from the collection
  /// - Parameter condition:  a closure defining the condition for removal
  private func remove(condition: (Packet) -> Bool) {
    for packet in _discovery!.packets where condition(packet) { 
      let removedPacket = _discovery?.packets.remove(id: packet.id)
      _discovery!.packetPublisher.send(PacketChange(.deleted, packet: removedPacket!))
      self._log("Discovery: Lan Listener packet removed, interval = \(abs(removedPacket!.lastSeen.timeIntervalSince(Date())))", .debug, #function, #file, #line)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncUdpSocketDelegate extension

extension LanListener: GCDAsyncUdpSocketDelegate {
  /// The Socket received data
  ///
  /// - Parameters:
  ///   - sock:           the GCDAsyncUdpSocket
  ///   - data:           the Data received
  ///   - address:        the Address of the sender
  ///   - filterContext:  the FilterContext
  public func udpSocket(_ sock: GCDAsyncUdpSocket,
                        didReceive data: Data,
                        fromAddress address: Data,
                        withFilterContext filterContext: Any?) {
    // VITA packet?
    guard let vita = Vita.decode(from: data) else { return }
    
    // YES, Discovery Packet?
    guard let packet = parseVita(vita) else { return }
    
    // YES, process it
    _discovery?.processPacket(packet)
  }
}
