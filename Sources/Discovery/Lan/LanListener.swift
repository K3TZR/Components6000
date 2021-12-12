//
//  LanListener.swift
//  TestDiscoveryPackage/Disc
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
}

/// Listener implementation
///
///      listens for the udp broadcasts announcing the presence
///      of a Flex-6000 Radio, publishes changes
///
final class LanListener: NSObject, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  @Published public private(set) var isConnected: Bool = false

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  weak var _discovery: Discovery?

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _cancellables = Set<AnyCancellable>()
  private let _udpQ = DispatchQueue(label: "DiscoveryListener" + ".udpQ")
  private var _udpSocket: GCDAsyncUdpSocket!

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(discovery: Discovery, port: UInt16 = 4992, checkInterval: TimeInterval = 1.0, timeout: TimeInterval = 10.0) throws {
    super.init()
    _discovery = discovery

    // create a Udp socket and set options
    let _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: _udpQ )
    _udpSocket.setPreferIPv4()
    _udpSocket.setIPv6Enabled(false)
    
    do {
      try _udpSocket.enableReusePort(true)
      try _udpSocket.bind(toPort: port)
      try _udpSocket.beginReceiving()
      DispatchQueue.main.async { self.isConnected = true }

    } catch {
      throw LanListenerError.kSocketError
    }
    // setup a timer to watch for Radio timeouts
    Timer.publish(every: checkInterval, on: .main, in: .default)
      .autoconnect()
      .sink { now in
        let deletedList = self._discovery!.packets.remove(condition: {
          $0.source == .local && abs($0.lastSeen.timeIntervalSince(now)) > timeout
        } )
        for packet in deletedList {
          self._discovery!.packetPublisher.send(PacketUpdate(.deleted, packet: packet, packets: self._discovery!.packets.collection))
        }
      }
      .store(in: &_cancellables)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// stop the listener
  func stop() {
    _cancellables = Set<AnyCancellable>()
    _udpSocket?.close()
    DispatchQueue.main.async { self.isConnected = false }
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
