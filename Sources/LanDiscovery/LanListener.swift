//
//  LanListener.swift
//  Components6000/Discovery/Lan
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import ComposableArchitecture
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
final public class LanListener: NSObject, ObservableObject {
  
  public var clientPublisher = PassthroughSubject<ClientUpdate, Never>()
  public var packetPublisher = PassthroughSubject<PacketUpdate, Never>()

  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
//  public private(set) var isListening: Bool = false

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
//  weak var _discovery: Discovery?

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _cancellables = Set<AnyCancellable>()
  private let _formatter = DateFormatter()
  private let _udpQ = DispatchQueue(label: "LanListener" + ".udpQ")
  private var _udpSocket: GCDAsyncUdpSocket!
  private var _packets: IdentifiedArrayOf<Packet> {
    get { Discovered.sharedInstance.packets }
    set { Discovered.sharedInstance.packets = newValue}}

//  let _log = LogProxy.sharedInstance.log
  
  let _log: Log = { msg,level,function,file,line in
    NotificationCenter.default.post(name: logEntryNotification, object: LogEntry(msg, level, function, file, line))
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(port: UInt16 = 4992) {
    super.init()
    
    _formatter.timeZone = .current
    _formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    // create a Udp socket and set options
    _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: _udpQ )
    _udpSocket.setPreferIPv4()
    _udpSocket.setIPv6Enabled(false)
    
    try! _udpSocket.enableReusePort(true)
    try! _udpSocket.bind(toPort: port)
    _log("Lan Listener: UDP Socket initialized", .debug, #function, #file, #line)
  }

  public func start(checkInterval: TimeInterval = 1.0, timeout: TimeInterval = 10.0) {
    try! _udpSocket.beginReceiving()
    _log("Lan Listener: is listening", .debug, #function, #file, #line)
    
    // setup a timer to watch for Radio timeouts
    Timer.publish(every: checkInterval, on: .main, in: .default)
      .autoconnect()
      .sink { now in
        self.remove(condition: { $0.source == .local && abs($0.lastSeen.timeIntervalSince(now)) > timeout } )
      }
      .store(in: &_cancellables)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// stop the listener
  public func stop() {
    _cancellables = Set<AnyCancellable>()
    _udpSocket?.close()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Remove a packet from the collection
  /// - Parameter condition:  a closure defining the condition for removal
  private func remove(condition: (Packet) -> Bool) {
    for packet in _packets where condition(packet) {
      let removedPacket = _packets.remove(id: packet.id)
      packetPublisher.send(PacketUpdate(.deleted, packet: removedPacket!))
      self._log("Lan Listener: packet removed, interval = \(abs(removedPacket!.lastSeen.timeIntervalSince(Date())))", .debug, #function, #file, #line)
    }
  }

  /// Parse a Vita class containing a Discovery broadcast
  /// - Parameter vita:   a Vita packet
  /// - Returns:          a DiscoveryPacket (or nil)
  private func parseVita(_ vita: Vita) -> Packet? {
    // is this a Discovery packet?
    if vita.classIdPresent && vita.classCode == .discovery {
      // Payload is a series of strings of the form <key=value> separated by ' ' (space)
      var payloadData = NSString(bytes: vita.payloadData, length: vita.payloadSize, encoding: String.Encoding.ascii.rawValue)! as String
      
      // eliminate any Nulls at the end of the payload
      payloadData = payloadData.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
      
      return Packet.populate( payloadData.keyValuesArray() )
    }
    return nil
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
    Discovered.sharedInstance.processPacket(packet)
  }
}
