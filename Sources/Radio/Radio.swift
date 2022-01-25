//
//  Radio.swift
//  Components6000/ApiObjects
//
//  Created by Douglas Adams on 1/12/22.
//

import Foundation
import Combine

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


  // Dynamic Model Collections
  @Published public var amplifiers = [AmplifierId: Amplifier]()
  @Published public var bandSettings = [BandId: BandSetting]()
  @Published public var daxIqStreams = [DaxIqStreamId: DaxIqStream]()
  @Published public var daxMicAudioStreams = [DaxMicStreamId: DaxMicAudioStream]()
  @Published public var daxRxAudioStreams = [DaxRxStreamId: DaxRxAudioStream]()
  @Published public var daxTxAudioStreams = [DaxTxStreamId: DaxTxAudioStream]()
  @Published public var equalizers = [Equalizer.EqType: Equalizer]()
  @Published public var memories = [MemoryId: Memory]()
  @Published public var meters = [MeterId: Meter]()
  @Published public var panadapters = [PanadapterStreamId: Panadapter]()
  @Published public var profiles = [ProfileId: Profile]()
  @Published public var remoteRxAudioStreams = [RemoteRxStreamId: RemoteRxAudioStream]()
  @Published public var remoteTxAudioStreams = [RemoteTxStreamId: RemoteTxAudioStream]()
  @Published public var slices = [SliceId: Slice]()
  @Published public var tnfs = [TnfId: Tnf]()
  @Published public var usbCables = [UsbCableId: UsbCable]()
  @Published public var waterfalls = [WaterfallStreamId: Waterfall]()
  @Published public var xvtrs = [XvtrId: Xvtr]()

  // Static Models
  @Published public private(set) var atu: Atu!
  @Published public private(set) var cwx: Cwx!
  @Published public private(set) var gps: Gps!
  @Published public private(set) var interlock: Interlock!
//  @Published public private(set) var netCwStream: NetCwStream!
  @Published public private(set) var transmit: Transmit!
  @Published public private(set) var wan: Wan!
  @Published public private(set) var waveform: Waveform!
//  @Published public private(set) var wanServer: WanServer!


  @Published public internal(set) var antennaList = [AntennaPort]()
  @Published public internal(set) var atuPresent = false
  @Published public internal(set) var availablePanadapters = 0
  @Published public internal(set) var availableSlices = 0
  @Published public internal(set) var backlight = 0
  @Published public internal(set) var bandPersistenceEnabled = false
  @Published public internal(set) var binauralRxEnabled = false
  @Published public var boundClientId: String?
  @Published public internal(set) var calFreq: MHz = 0
  @Published public internal(set) var callsign = ""
  @Published public internal(set) var chassisSerial = ""
  @Published public internal(set) var daxIqAvailable = 0
  @Published public internal(set) var daxIqCapacity = 0
  @Published public internal(set) var enforcePrivateIpEnabled = false
  @Published public internal(set) var extPresent = false
  @Published public internal(set) var filterCwAutoEnabled = false
  @Published public internal(set) var filterDigitalAutoEnabled = false
  @Published public internal(set) var filterVoiceAutoEnabled = false
  @Published public internal(set) var filterCwLevel = 0
  @Published public internal(set) var filterDigitalLevel = 0
  @Published public internal(set) var filterVoiceLevel = 0
  @Published public internal(set) var fpgaMbVersion = ""
  @Published public internal(set) var freqErrorPpb = 0
  @Published public internal(set) var frontSpeakerMute = false
  @Published public internal(set) var fullDuplexEnabled = false
  @Published public internal(set) var gateway = ""
  @Published public internal(set) var gpsPresent = false
  @Published public internal(set) var gpsdoPresent = false
  @Published public internal(set) var headphoneGain = 0
  @Published public internal(set) var headphoneMute = false
  @Published public internal(set) var ipAddress = ""
  @Published public internal(set) var lineoutGain = 0
  @Published public internal(set) var lineoutMute = false
  @Published public internal(set) var localPtt = false
  @Published public internal(set) var location = ""
  @Published public internal(set) var locked = false
  @Published public internal(set) var macAddress = ""
  @Published public internal(set) var micList = [MicrophonePort]()
  @Published public internal(set) var mox = false
  @Published public internal(set) var muteLocalAudio = false
  @Published public internal(set) var netmask = ""
  @Published public internal(set) var nickname = ""
  @Published public internal(set) var numberOfScus = 0
  @Published public internal(set) var numberOfSlices = 0
  @Published public internal(set) var numberOfTx = 0
  @Published public internal(set) var oscillator = ""
  @Published public internal(set) var picDecpuVersion = ""
  @Published public internal(set) var program = ""
  @Published public internal(set) var psocMbPa100Version = ""
  @Published public internal(set) var psocMbtrxVersion = ""
  @Published public internal(set) var radioAuthenticated = false
  @Published public internal(set) var radioModel = ""
  @Published public internal(set) var radioOptions = ""
  @Published public internal(set) var region = ""
  @Published public internal(set) var radioScreenSaver = ""
  @Published public internal(set) var remoteOnEnabled = false
  @Published public internal(set) var rttyMark = 0
  @Published public internal(set) var serverConnected = false
  @Published public internal(set) var setting = ""
  @Published public internal(set) var sliceList = [SliceId]()
  @Published public internal(set) var smartSdrMB = ""
  @Published public internal(set) var snapTuneEnabled = false
  @Published public internal(set) var softwareVersion = ""
  @Published public internal(set) var startCalibration = false
  @Published public internal(set) var state = ""
  @Published public internal(set) var staticGateway = ""
  @Published public internal(set) var staticIp = ""
  @Published public internal(set) var staticNetmask = ""
  @Published public internal(set) var station = ""
  @Published public internal(set) var tnfsEnabled = false
  @Published public internal(set) var tcxoPresent = false
  @Published public internal(set) var uptime = 0


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
    case clientConnected (radio: Radio)
    case tcpDisconnected (reason: String)
    case wanHandleValidated (success: Bool)
    case udpUnbound (reason: String)
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
  var _cancellableCommandData: AnyCancellable?
  var _cancellableCommandStatus: AnyCancellable?
  var _cancellableStreamData: AnyCancellable?
  var _cancellableStreamStatus: AnyCancellable?
  var _clientId: String?
  var _clientInitialized = false
  var _command: TcpCommand
  let _connectionType: ConnectionType
  var _disconnectHandle: Handle?
  let _domain: String
  let _log = LogProxy.sharedInstance.log
  var _lowBandwidthConnect = false
  var _lowBandwidthDax = false
  var _metersAreStreaming = false
  var _params: ConnectionParams!
  let _parseQ = DispatchQueue(label: "Radio.parseQ", qos: .userInteractive)
  var _pinger: Pinger?
  var _programName: String?
  var _radioInitialized = false
  var _replyHandlers = [SequenceNumber: ReplyTuple]()
  var _stationName: String?
  var _stream: UdpStream
  var _testerModeEnabled: Bool

  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ packet: Packet, connectionType: ConnectionType, command: TcpCommand, stream: UdpStream, stationName: String? = nil, programName: String? = nil, lowBandwidthConnect: Bool = false, lowBandwidthDax: Bool = false, disconnectHandle: Handle? = nil, testerModeEnabled: Bool = false) {
    self.packet = packet
    _connectionType = connectionType
    _command = command
    _stream = stream
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
    atu = Atu()
    cwx = Cwx()
    gps = Gps()
    interlock = Interlock()
//    netCwStream = NetCwStream()
    transmit = Transmit()
    wan = Wan()
    waveform = Waveform()

    // initialize Equalizers
    equalizers[.rxsc] = Equalizer(Equalizer.EqType.rxsc.rawValue)
    equalizers[.txsc] = Equalizer(Equalizer.EqType.txsc.rawValue)

    // subscribe to the publisher of TcpCommands received messages
    _cancellableCommandData = command.receivedPublisher
      .receive(on: _parseQ)
      .sink { [weak self] msg in
        self?.receivedMessage(msg)
      }

    _cancellableCommandStatus = command.statusPublisher
      .receive(on: _parseQ)
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
//    _cancellableStreamStatus = stream.statusPublisher
//      .receive(on: _parseQ)
//      .sink { [weak self] status in
//        self?.streamStatus(status)
//      }
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
    return _command.connect(packet) 
  }

  /// Send a command to the Radio (hardware)
  /// - Parameters:
  ///   - command:        a Command String
  ///   - flag:           use "D"iagnostic form
  ///   - callback:       a callback function (if any)
  public func send(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil) {
    
    // tell TcpCommands to send the command
    let sequenceNumber = _command.send(command, diagnostic: flag)
    
    // register to be notified when reply received
    addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
  }

  /// Send data to the Radio (hardware)
  /// - Parameters:
  ///   - data:        data
  public func send(_ data: Data) {
    // tell UdpStreams to send the data
    _stream.send(data)
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

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods

  func tcpStatus(_ status: TcpStatus) {
    switch status.statusType {
      
    case .didConnect:     updateState(to: .tcpConnected(host: status.host, port: status.port))
    case .didSecure:      break
    case .didDisconnect:  updateState(to: .tcpDisconnected(reason: status.reason ?? ""))
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
//      NC.post(.tcpDidConnect, object: nil)

      if packet.source == .smartlink {
        _log("Radio: Validate Wan handle = \(packet.wanHandle)", .debug, #function, #file, #line)
        send("wan validate handle=" + packet.wanHandle, replyTo: wanValidateReplyHandler)

      } else {
        // bind a UDP port for the Streams
        if _stream.bind(packet) == false { _command.disconnect() }

        // FIXME: clientHandle is not used by bind????
      }

    case .wanHandleValidated (let success):
      if success {
        _log("Radio: Wan handle validated", .debug, #function, #file, #line)
        if _stream.bind(packet) == false { _command.disconnect() }
      } else {
        _log("Radio: Wan handle validation FAILED", .debug, #function, #file, #line)
        _command.disconnect()
      }

    case .udpBound (let receivePort, let sendPort):
      _log("Radio: UDP bound, receive port = \(receivePort), send port = \(sendPort)", .debug, #function, #file, #line)

      // if a Wan connection, register
      if packet.source == .smartlink { _stream.register(clientHandle: connectionHandle) }

      // a UDP port has been bound, inform observers
//      NC.post(.udpDidBind, object: nil)

    case .clientConnected:
      _log("Radio: client connected (LOCAL)", .debug, #function, #file, #line)

      // complete the connection
      connectionCompletion()

      // Disconnection --------------------------------------------------------------------------
    case .tcpDisconnected (let reason):
      _log("Radio: Tcp Disconnected, reason = \(reason)", .debug, #function, #file, #line)
//      NC.post(.tcpDidDisconnect, object: reason)

      // close the UDP port (it won't be reused with a new connection)
      _stream.unbind(reason: "TCP Disconnected")

    case .udpUnbound (let reason):
      _log("Radio: UDP unbound, reason = \(reason)", .debug, #function, #file, #line)
      updateState(to: .clientDisconnected)

    case .clientDisconnected:
      _log("Radio: Client disconnected", .debug, #function, #file, #line)

      // Not Implemented ------------------------------------------------------------------------
    case .update:
      _log("Radio: Firmware Update not implemented", .warning, #function, #file, #line)
      break
    }
  }

  /// executed after an IP Address has been obtained
  func connectionCompletion() {
    _log("Radio: connectionCompletion for \(packet.nickname)", .debug, #function, #file, #line)

    // normal connection?
    if _disconnectHandle == nil {
      // YES, send the initial commands
      sendCommands()

      // set the UDP port for a Local connection
      if packet.source == .local { send("client udpport " + "\(_stream.sendPort)") }

      // start pinging the Radio
      if pingerEnabled { _pinger = Pinger(radio: self, command: _command) }

    } else {
      // NO, pending disconnect
      send("client disconnect \(_disconnectHandle!.hex)")

      // give client disconnection time to happen
      sleep(1)
      _command.disconnect()
      sleep(1)

      // reconnect
      _disconnectHandle = nil
      _clientInitialized = false
      _ = _command.connect(packet)
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

  /// Process received UDP Vita packets
  ///   arrives on the udpReceiveQ
  ///
  /// - Parameter vitaPacket:       a Vita packet
  public func vitaParser(_ vitaPacket: Vita) {
      // Pass the stream to the appropriate object
      switch (vitaPacket.classCode) {
      
      case .meter:
          // unlike other streams, the Meter stream contains multiple Meters
          // and is processed by a class method on the Meter object
          Meter.vitaProcessor(vitaPacket, radio: self)
          if _metersAreStreaming == false {
              _metersAreStreaming = true
              // log the start of the stream
              _log("Radio, Meter Stream started", .info, #function, #file, #line)
          }

      case .panadapter:
          if let object = panadapters[vitaPacket.streamId]          { object.vitaProcessor(vitaPacket) }
          
      case .waterfall:
          if let object = waterfalls[vitaPacket.streamId]           { object.vitaProcessor(vitaPacket) }
          
      case .daxAudio:
          if let object = daxRxAudioStreams[vitaPacket.streamId]    { object.vitaProcessor(vitaPacket)}
          if let object = daxMicAudioStreams[vitaPacket.streamId]   { object.vitaProcessor(vitaPacket) }
          if let object = remoteRxAudioStreams[vitaPacket.streamId] { object.vitaProcessor(vitaPacket) }
          
      case .daxReducedBw:
          if let object = daxRxAudioStreams[vitaPacket.streamId]    { object.vitaProcessor(vitaPacket) }
          if let object = daxMicAudioStreams[vitaPacket.streamId]   { object.vitaProcessor(vitaPacket) }
          
      case .opus:
          if let object = remoteRxAudioStreams[vitaPacket.streamId] { object.vitaProcessor(vitaPacket) }
          
      case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
          if let object = daxIqStreams[vitaPacket.streamId]         { object.vitaProcessor(vitaPacket) }
          
      default:
          // log the error
          _log("Radio, unknown Vita class code: \(vitaPacket.classCode.description()) Stream Id = \(vitaPacket.streamId.hex)", .error, #function, #file, #line)
      }
  }

}
