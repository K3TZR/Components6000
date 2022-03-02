//
//  Radio.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 1/12/22.
//

import Foundation
import Combine

import Discovery
import TcpCommands
import UdpStreams
import Shared

public final class Radio: Equatable {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public static func == (lhs: Radio, rhs: Radio) -> Bool { lhs === rhs }
  public static let objectQ = DispatchQueue(label: "Radio.objectQ", attributes: [.concurrent])
  
  public static let kDaxChannels      = ["None", "1", "2", "3", "4", "5", "6", "7", "8"]
  public static let kDaxIqChannels    = ["None", "1", "2", "3", "4"]
  
  public var packet: Packet
  public var pingerEnabled = true
  public var radioState: RadioState = .clientDisconnected
  public var connectionHandle: Handle?
  public var hardwareVersion: String?
  public var replyHandlers : [SequenceNumber: ReplyTuple] {
    get { Radio.objectQ.sync { _replyHandlers } }
    set { Radio.objectQ.sync(flags: .barrier) { _replyHandlers = newValue }}}
    
  public internal(set) var antennaList = [AntennaPort]()
  public internal(set) var atuPresent = false
  public internal(set) var availablePanadapters = 0
  public internal(set) var availableSlices = 0
  public internal(set) var backlight = 0
  public internal(set) var bandPersistenceEnabled = false
  public internal(set) var binauralRxEnabled = false
  public var boundClientId: String?
  public internal(set) var calFreq: MHz = 0
  public internal(set) var callsign = ""
  public internal(set) var chassisSerial = ""
  public internal(set) var daxIqAvailable = 0
  public internal(set) var daxIqCapacity = 0
  public internal(set) var enforcePrivateIpEnabled = false
  public internal(set) var extPresent = false
  public internal(set) var filterCwAutoEnabled = false
  public internal(set) var filterDigitalAutoEnabled = false
  public internal(set) var filterVoiceAutoEnabled = false
  public internal(set) var filterCwLevel = 0
  public internal(set) var filterDigitalLevel = 0
  public internal(set) var filterVoiceLevel = 0
  public internal(set) var fpgaMbVersion = ""
  public internal(set) var freqErrorPpb = 0
  public internal(set) var frontSpeakerMute = false
  public internal(set) var fullDuplexEnabled = false
  public internal(set) var gateway = ""
  public internal(set) var gpsPresent = false
  public internal(set) var gpsdoPresent = false
  public internal(set) var headphoneGain = 0
  public internal(set) var headphoneMute = false
  public internal(set) var ipAddress = ""
  public internal(set) var lineoutGain = 0
  public internal(set) var lineoutMute = false
  public internal(set) var localPtt = false
  public internal(set) var location = ""
  public internal(set) var locked = false
  public internal(set) var macAddress = ""
  public internal(set) var micList = [MicrophonePort]()
  public internal(set) var mox = false
  public internal(set) var muteLocalAudio = false
  public internal(set) var netmask = ""
  public internal(set) var nickname = ""
  public internal(set) var numberOfScus = 0
  public internal(set) var numberOfSlices = 0
  public internal(set) var numberOfTx = 0
  public internal(set) var oscillator = ""
  public internal(set) var picDecpuVersion = ""
  public internal(set) var program = ""
  public internal(set) var psocMbPa100Version = ""
  public internal(set) var psocMbtrxVersion = ""
  public internal(set) var radioAuthenticated = false
  public internal(set) var radioModel = ""
  public internal(set) var radioOptions = ""
  public internal(set) var region = ""
  public internal(set) var radioScreenSaver = ""
  public internal(set) var remoteOnEnabled = false
  public internal(set) var rfGainList = [RfGainValue]()
  public internal(set) var rttyMark = 0
  public internal(set) var serverConnected = false
  public internal(set) var setting = ""
  public internal(set) var sliceList = [SliceId]()
  public internal(set) var smartSdrMB = ""
  public internal(set) var snapTuneEnabled = false
  public internal(set) var softwareVersion = ""
  public internal(set) var startCalibration = false
  public internal(set) var state = ""
  public internal(set) var staticGateway = ""
  public internal(set) var staticIp = ""
  public internal(set) var staticNetmask = ""
  public internal(set) var station = ""
  public internal(set) var tnfsEnabled = false
  public internal(set) var tcxoPresent = false
  public internal(set) var uptime = 0
  
  
  public struct ConnectionParams {
    public init(index: Int,
                //                  station: String = "",
                //                  program: String = "",
                clientId: String? = nil,
                isGui: Bool = true,
                wanHandle: String = "",
                //                  lowBandwidthConnect: Bool = false,
                //                  lowBandwidthDax: Bool = false,
                //                  needsCwStream: Bool = false,
                pendingDisconnect: Radio.PendingDisconnect = PendingDisconnect.none) {
      
      self.index = index
      //          self.station = station
      //          self.program = program
      self.clientId = clientId
      self.isGui = isGui
      self.wanHandle = wanHandle
      //          self.lowBandwidthConnect = lowBandwidthConnect
      //          self.lowBandwidthDax = lowBandwidthDax
      //          self.needsCwStream = needsCwStream
      self.pendingDisconnect = pendingDisconnect
    }
    
    public var index: Int
    //      public var station = ""
    //      public var program = ""
    public var clientId: String?
    public var isGui = true
    public var wanHandle = ""
    //      public var lowBandwidthConnect = false
    //      public var lowBandwidthDax = false
    //      public var needsCwStream = false
    public var pendingDisconnect = PendingDisconnect.none
  }
  
  public enum PendingDisconnect: Equatable {
    case none
    case some (handle: Handle)
  }
  
  public enum RadioState {
    case tcpConnected (host: String, port: UInt16)
    case udpBound (receivePort: UInt16, sendPort: UInt16)
    case clientDisconnected
    case clientConnected
    case tcpDisconnected (reason: String?)
    case wanHandleValidated (success: Bool)
    case udpUnbound (reason: String?)
    case update
    
    public static func ==(lhs: RadioState, rhs: RadioState) -> Bool {
      switch (lhs, rhs) {
      case (.tcpConnected, .tcpConnected):                  return true
      case (.udpBound, .udpBound):                          return true
      case (.clientDisconnected, .clientDisconnected):      return true
      case (.clientConnected, .clientConnected):            return true
      case (.tcpDisconnected, .tcpDisconnected):            return true
      case (.wanHandleValidated, .wanHandleValidated):      return true
      case (.udpUnbound, .udpUnbound):                      return true
      case (.update, .update):                              return true
      default:                                              return false
      }
    }
    public static func !=(lhs: RadioState, rhs: RadioState) -> Bool {
      return !(lhs == rhs)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  let _appName: String
  var _cancellableClientUpdate: AnyCancellable?
  var _cancellableCommandData: AnyCancellable?
  var _cancellableCommandStatus: AnyCancellable?
  var _cancellablePacketUpdate: AnyCancellable?
  var _cancellableStreamData: AnyCancellable?
  var _cancellableStreamStatus: AnyCancellable?
  var _clientId: String?
  var _clientInitialized = false
  let _connectionType: ConnectionType
  var _disconnectHandle: Handle?
  let _domain: String
  let _log = LogProxy.sharedInstance.log
  var _lowBandwidthConnect = false
  var _lowBandwidthDax = false
  public var objects = Objects.sharedInstance
  var _params: ConnectionParams!
  let _parseQ = DispatchQueue(label: "Radio.parseQ", qos: .userInteractive)
  var _pinger: Pinger?
  var _programName: String?
  var _radioInitialized = false
  var _replyHandlers = [SequenceNumber: ReplyTuple]()
  var _stationName: String?
  var _tcp: Tcp
  var _testerModeEnabled: Bool
  var _udp: Udp

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ packet: Packet, connectionType: ConnectionType, command: Tcp, stream: Udp, stationName: String? = nil, programName: String? = nil, lowBandwidthConnect: Bool = false, lowBandwidthDax: Bool = false, disconnectHandle: Handle? = nil, testerModeEnabled: Bool = false) {
    self.packet = packet
    _connectionType = connectionType
    _tcp = command
    _udp = stream
    _lowBandwidthConnect = lowBandwidthConnect
    _lowBandwidthDax = lowBandwidthDax
    _stationName = stationName
    _programName = programName
    _disconnectHandle = disconnectHandle
    _testerModeEnabled = testerModeEnabled
    
    let bundleIdentifier = Bundle.main.bundleIdentifier ?? "net.k3tzr.Radio"
    let separator = bundleIdentifier.lastIndex(of: ".")!
    _appName = String(bundleIdentifier.suffix(from: bundleIdentifier.index(separator, offsetBy: 1)))
    _domain = String(bundleIdentifier.prefix(upTo: separator))
        
    // initialize the static models (only one of each is ever created)
    objects.atu = Atu()
    objects.cwx = Cwx()
    objects.gps = Gps()
    objects.interlock = Interlock()
    //    _objects.netCwStream = NetCwStream()
    objects.transmit = Transmit()
    objects.wan = Wan()
    objects.waveform = Waveform()
    
    // initialize Equalizers
    objects.equalizers[id: Equalizer.EqType.rxsc.rawValue] = Equalizer(Equalizer.EqType.rxsc.rawValue)
    objects.equalizers[id: Equalizer.EqType.txsc.rawValue] = Equalizer(Equalizer.EqType.txsc.rawValue)
    
    // subscribe to the publisher of TcpCommands received messages
    _cancellableCommandData = command.receivedPublisher
      .receive(on: _parseQ)
      .sink { [weak self] msg in
        self?.receivedMessage(msg)
      }
    
    _cancellableCommandStatus = command.statusPublisher
      .sink { [weak self] status in
        self?.tcpStatus(status)
      }
    
    // subscribe to the publisher of UdpStreams data
    _cancellableStreamData = stream.streamPublisher
      .receive(on: _parseQ)
      .sink { [weak self] vita in
        self?.vitaParser(vita)
      }
    
    // subscribe to the publisher of UdpStreams status
    _cancellableStreamStatus = stream.statusPublisher
      .sink { [weak self] status in
        self?.udpStatus(status)
      }
    
    _cancellablePacketUpdate = Discovery.sharedInstance.packetPublisher
      .sink { [weak self] update in
        self?.packetUpdate(update)
      }

    _cancellableClientUpdate = Discovery.sharedInstance.clientPublisher
      .sink { [weak self] update in
        self?.clientUpdate(update)
      }
  }
  
  
  func packetUpdate(_ update: PacketUpdate) {
    _log("Radio: \(update.packet.source.rawValue) packet \(update.packet.nickname) \(update.action.rawValue)", .info, #function, #file, #line)
  }
  
  func clientUpdate(_ update: ClientUpdate) {
    _log("Radio: \(update.source.rawValue) client \(update.client.station) \(update.action.rawValue)", .info, #function, #file, #line)
  }

  
  
  
  
  
  
  
  /// Connect to this Radio
  ///
  ///   ----- v3 API explanation -----
  ///
  ///   Definitions
  ///     Client:    The application using a radio
  ///     Api:        The intermediary between the Client and a Radio (e.g. FlexLib, xLib6001, etc.)
  ///     Radio:    The physical radio (e.g. a Flex-6500)
  ///
  ///   There are 5 scenarios:
  ///
  ///     1. The Client connects as a Gui, ClientId is known
  ///         The Client passes clientId = <ClientId>, isGui = true to the Api
  ///         The Api sends a "client gui <ClientId>" command to the Radio
  ///
  ///     2. The Client connects as a Gui, ClientId is NOT known
  ///         The Client passes clientId = nil, isGui = true to the Api
  ///         The Api sends a "client gui" command to the Radio
  ///         The Radio generates a ClientId
  ///         The Client receives GuiClientHasBeenAdded / Removed / Updated notification(s)
  ///         The Client finds the desired ClientId
  ///         The Client persists the ClientId (if desired))
  ///
  ///     3. The Client connects as a non-Gui, binding is desired, ClientId is known
  ///         The Client passes clientId = <ClientId>, isGui = false to the Api
  ///         The Api sends a "client bind <ClientId>" command to the Radio
  ///
  ///     4. The Client connects as a non-Gui, binding is desired, ClientId is NOT known
  ///         The Client passes clientId = nil, isGui = false to the Api
  ///         The Client receives GuiClientHasBeenAdded / Removed / Updated notification(s)
  ///         The Client finds the desired ClientId
  ///         The Client sets the boundClientId property on the radio class of the Api
  ///         The radio class causes a "client bind client_id=<ClientId>" command to be sent to the Radio
  ///         The Client persists the ClientId (if desired))
  ///
  ///     5. The Client connects as a non-Gui, binding is NOT desired
  ///         The Client passes clientId = nil, isGui = false to the Api
  ///
  ///     Scenarios 2 & 4 are typically executed once which then allows the Client to use scenarios 1 & 3
  ///     for all subsequent connections (if the Client has persisted the ClientId)
  ///
  /// - Parameter params:     a struct of parameters
  /// - Returns:              success / failure
  public func connect(_ packet: Packet) -> Bool {
    guard radioState == .clientDisconnected else {
      _log("Radio: Invalid state on connect, apiState != .clientDisconnected", .warning, #function, #file, #line)
      return false
    }
    // attempt to connect
    return _tcp.connect(packet)
  }
  
  /// Disconnect from the Radio
  public func disconnect() {
    _tcp.disconnect()
  }
  
  /// Send a command to the Radio (hardware)
  /// - Parameters:
  ///   - command:        a Command String
  ///   - flag:           use "D"iagnostic form
  ///   - callback:       a callback function (if any)
  public func send(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil) {
    // tell TcpCommands to send the command
    let sequenceNumber = _tcp.send(command, diagnostic: flag)
    
    // register to be notified when reply received
    addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
  }
  
  /// Send data to the Radio (hardware)
  /// - Parameters:
  ///   - data:        data
  public func send(_ data: Data) {
    // tell UdpStreams to send the data
    _udp.send(data)
  }
  
  /// Determine if status is for this client
  /// - Parameters:
  ///   - properties:     a KeyValuesArray
  ///   - clientHandle:   the handle of ???
  /// - Returns:          true if a mtch
  public func isForThisClient(_ properties: KeyValuesArray, connectionHandle: Handle?) -> Bool {
    var clientHandle : Handle = 0
    
    guard connectionHandle != nil else { return false }
    
    // allow a Tester app to see all Streams
    guard _testerModeEnabled == false else { return true }
    
    // find the handle property
    for property in properties.dropFirst(2) where property.key == "client_handle" {
      clientHandle = property.value.handle ?? 0
    }
    return clientHandle == connectionHandle
  }
  
  /// Process received UDP Vita packets
  ///   arrives on the udpReceiveQ
  ///
  /// - Parameter vitaPacket:       a Vita packet
  public func vitaParser(_ vitaPacket: Vita) {
    
    let _testMode = false
    
    // Pass the stream to the appropriate object
    switch (vitaPacket.classCode) {
      
    case .meter:
      // unlike other streams, the Meter stream contains multiple Meters
      // and is processed by a class method on the Meter object
      Meter.vitaProcessor(vitaPacket, radio: self)
      
    case .panadapter:
      if let object = objects.panadapters[id: vitaPacket.streamId]          { object.vitaProcessor(vitaPacket, _testMode) }
      
    case .waterfall:
      if let object = objects.waterfalls[id: vitaPacket.streamId]           { object.vitaProcessor(vitaPacket, _testMode) }
      
    case .daxAudio:
      if let object = objects.daxRxAudioStreams[id: vitaPacket.streamId]    { object.vitaProcessor(vitaPacket)}
      if let object = objects.daxMicAudioStreams[id: vitaPacket.streamId]   { object.vitaProcessor(vitaPacket) }
      if let object = objects.remoteRxAudioStreams[id: vitaPacket.streamId] { object.vitaProcessor(vitaPacket) }
      
    case .daxReducedBw:
      if let object = objects.daxRxAudioStreams[id: vitaPacket.streamId]    { object.vitaProcessor(vitaPacket) }
      if let object = objects.daxMicAudioStreams[id: vitaPacket.streamId]   { object.vitaProcessor(vitaPacket) }
      
    case .opus:
      if let object = objects.remoteRxAudioStreams[id: vitaPacket.streamId] { object.vitaProcessor(vitaPacket) }
      
    case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
      if let object = objects.daxIqStreams[id: vitaPacket.streamId]         { object.vitaProcessor(vitaPacket) }
      
    default:
      // log the error
      _log("Radio, unknown Vita class code: \(vitaPacket.classCode.description()) Stream Id = \(vitaPacket.streamId.hex)", .error, #function, #file, #line)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func tcpStatus(_ status: TcpStatus) {
    switch status.statusType {
      
    case .didConnect, .didSecure:   updateState(to: .tcpConnected(host: status.host, port: status.port))
    case .didDisconnect:            updateState(to: .tcpDisconnected(reason: status.reason ?? "User Initiated"))
    }
  }
 
  func udpStatus(_ status: UdpStatus) {
    switch status.statusType {
      
    case .didBind:        updateState(to: .udpBound(receivePort: status.receivePort, sendPort: status.sendPort))
    case .didUnBind:      updateState(to: .udpUnbound(reason: status.error?.localizedDescription))
    case .failedToBind:   break // FIXME:
    case .readError:      break // FIXME:
    }
  }

  /// Change the state of the Radio
  /// - Parameter newState: the new
  func updateState(to newState: RadioState) {
    radioState = newState
    
    switch radioState {
      
      // Connection -----------------------------------------------------------------------------
    case .tcpConnected (let host, let port):
      _log("Radio: TCP connected to \(host), port \(port)", .debug, #function, #file, #line)
      
      if packet.source == .smartlink {
        _log("Radio: Validate Wan handle = \(packet.wanHandle)", .debug, #function, #file, #line)
        send("wan validate handle=" + packet.wanHandle, replyTo: wanValidateReplyHandler)
        
      } else {
        // bind a UDP port for the Streams
        if _udp.bind(packet) == false { _tcp.disconnect() }
      }
      
    case .wanHandleValidated (let success):
      if success {
        _log("Radio: Wan handle validated", .debug, #function, #file, #line)
        if _udp.bind(packet) == false { _tcp.disconnect() }
      } else {
        _log("Radio: Wan handle validation FAILED", .debug, #function, #file, #line)
        _tcp.disconnect()
      }
      
    case .udpBound (let receivePort, let sendPort):
      _log("Radio: UDP bound, receive port = \(receivePort), send port = \(sendPort)", .debug, #function, #file, #line)
      
      // if a Wan connection, register
      if packet.source == .smartlink { _udp.register(clientHandle: connectionHandle) }
      
    case .clientConnected where packet.source == .smartlink:
        // when connecting to a WAN radio, the public IP address of the connected
        // client must be obtained from the radio.  This value is used to determine
        // if audio streams from the radio are meant for this client.
        // (isForThisClient(...) checks)
        send("client ip", replyTo: clientIpReplyHandler)

    case .clientConnected:
      _log("Radio: client connected (LOCAL)", .debug, #function, #file, #line)
      
      // complete the connection
      connectionCompletion()
      
      // Disconnection --------------------------------------------------------------------------
    case .tcpDisconnected (let reason):
      _log("Radio: Tcp Disconnected, \(reason ?? "User initiated")", .debug, #function, #file, #line)
      
      // stop all streams
      _udp.unbind(reason: reason ?? "User initiated")
      
      // stop pinging (if active)
      _pinger?.stopPinging()
      _pinger = nil
      
      // remove all of radio's objects
      removeAllObjects()

    case .udpUnbound (let reason):
      _log("Radio: UDP unbound, \(reason ?? "User initiated")", .debug, #function, #file, #line)
      updateState(to: .clientDisconnected)
      
    case .clientDisconnected:
      _log("Radio: Client disconnected", .debug, #function, #file, #line)
      
      // Not Implemented ------------------------------------------------------------------------
    case .update:
      _log("Radio: Firmware Update not implemented", .warning, #function, #file, #line)
      break
    }
  }

  /// Reply handler for the "client ip" command
  /// - Parameters:
  ///   - command:                a Command string
  ///   - seqNum:                 the Command's sequence number
  ///   - responseValue:          the response contained in the Reply to the Command
  ///   - reply:                  the descriptive text contained in the Reply to the Command
  private func clientIpReplyHandler(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    connectionCompletion()
  }

  /// executed after an IP Address has been obtained
  func connectionCompletion() {
    _log("Radio: connectionCompletion for \(packet.nickname)", .debug, #function, #file, #line)
    
    // normal connection?
    if _disconnectHandle == nil {
      // YES, send the initial commands
      sendCommands()
      
      // set the UDP port for a Local connection
      if packet.source == .local { send("client udpport " + "\(_udp.sendPort)") }
      
      // start pinging the Radio
      if pingerEnabled {
        _pinger = Pinger(radio: self)
        _log("Radio: pinger started", .info, #function, #file, #line)
      }
      
    } else {
      // NO, pending disconnect
      send("client disconnect \(_disconnectHandle!.hex)")
      
      // give client disconnection time to happen
      sleep(1)
      _tcp.disconnect()
      sleep(1)
      
      // reconnect
      _disconnectHandle = nil
      _clientInitialized = false
      _ = _tcp.connect(packet)
    }
  }
  
  /// Send commands to configure the connection
  func sendCommands() {
    if _connectionType == .gui && _clientId != nil {
      send("client gui " + _clientId!)
    } else {
      send("client gui")
    }
    send("client program " + (_programName != nil ? _programName! : "MacProgram"))
    if _connectionType == .gui { send("client station " + (_stationName != nil ? _stationName! : "Mac")) }
    if _connectionType != .gui && _clientId != nil { bindGuiClient(_clientId!) }
    if _lowBandwidthConnect { requestLowBandwidthConnect() }
    requestInfo()
    requestVersion()
    requestAntennaList()
    requestMicList()
    requestGlobalProfile()
    requestTxProfile()
    requestMicProfile()
    requestDisplayProfile()
    requestSubAll()
    requestMtuLimit(1_500)
    requestLowBandwidthDax(_lowBandwidthDax)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Remove all Radio objects
  private func removeAllObjects() {    
    // ----- remove all objects -----, NOTE: order is important
    objects.daxRxAudioStreams.removeAll()
    objects.daxIqStreams.removeAll()
    objects.daxMicAudioStreams.removeAll()
    objects.daxTxAudioStreams.removeAll()
    objects.remoteRxAudioStreams.removeAll()
    objects.remoteTxAudioStreams.removeAll()
    objects.tnfs.removeAll()
    objects.slices.removeAll()
    objects.panadapters.removeAll()
    objects.waterfalls.removeAll()
    objects.profiles.forEach {
      $0.list.removeAll()
    }
    objects.equalizers.removeAll()
    objects.memories.removeAll()
    objects.meters.removeAll()
    replyHandlers.removeAll()
    objects.usbCables.removeAll()
    objects.xvtrs.removeAll()
    
    nickname = ""
    smartSdrMB = ""
    psocMbtrxVersion = ""
    psocMbPa100Version = ""
    fpgaMbVersion = ""
    
    // clear lists
    antennaList.removeAll()
    micList.removeAll()
    rfGainList.removeAll()
    sliceList.removeAll()
    
    _clientInitialized = false
  }
}
