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
  public static let kName             = "xLib6001"

  public static let kConnected        = "connected"
  public static let kDisconnected     = "disconnected"
  public static let kNotInUse         = "in_use=0"
  public static let kRemoved          = "removed"


  public var pingerEnabled = true
  public var radioState: RadioState = .clientDisconnected
  public var connectionHandle: Handle?
  public var hardwareVersion: String?
  public var replyHandlers : [SequenceNumber: ReplyTuple] {
    get { Radio.objectQ.sync { _replyHandlers } }
      set { Radio.objectQ.sync(flags: .barrier) { _replyHandlers = newValue }}}


  // Dynamic Model Collections
//  @Published public var amplifiers = [AmplifierId: Amplifier]()
  @Published public var bandSettings = [BandId: BandSetting]()
//  @Published public var daxIqStreams = [DaxIqStreamId: DaxIqStream]()
//  @Published public var daxMicAudioStreams = [DaxMicStreamId: DaxMicAudioStream]()
//  @Published public var daxRxAudioStreams = [DaxRxStreamId: DaxRxAudioStream]()
//  @Published public var daxTxAudioStreams = [DaxTxStreamId: DaxTxAudioStream]()
  @Published public var equalizers = [Equalizer.EqType: Equalizer]()
//  @Published public var memories = [MemoryId: Memory]()
//  @Published public var meters = [MeterId: Meter]()
//  @Published public var panadapters = [PanadapterStreamId: Panadapter]()
//  @Published public var profiles = [ProfileId: Profile]()
//  @Published public var remoteRxAudioStreams = [RemoteRxStreamId: RemoteRxAudioStream]()
//  @Published public var remoteTxAudioStreams = [RemoteTxStreamId: RemoteTxAudioStream]()
//  @Published public var slices = [SliceId: Slice]()
  @Published public var tnfs = [TnfId: Tnf]()
//  @Published public var usbCables = [UsbCableId: UsbCable]()
//  @Published public var waterfalls = [WaterfallStreamId: Waterfall]()
//  @Published public var xvtrs = [XvtrId: Xvtr]()

  // Static Models
//  @Published public private(set) var atu: Atu!
//  @Published public private(set) var cwx: Cwx!
//  @Published public private(set) var gps: Gps!
  @Published public private(set) var interlock: Interlock!
//  @Published public private(set) var netCwStream: NetCwStream!
//  @Published public private(set) var transmit: Transmit!
//  @Published public private(set) var waveform: Waveform!
//  @Published public private(set) var wanServer: WanServer!


  @Published public private(set) var antennaList = [AntennaPort]()
  @Published public private(set) var atuPresent = false
  @Published public private(set) var availablePanadapters = 0
  @Published public private(set) var availableSlices = 0
  @Published public private(set) var backlight = 0
  @Published public private(set) var bandPersistenceEnabled = false
  @Published public private(set) var binauralRxEnabled = false
  @Published public var boundClientId: String?
  @Published public private(set) var calFreq: MHz = 0
  @Published public private(set) var callsign = ""
  @Published public private(set) var chassisSerial = ""
  @Published public private(set) var daxIqAvailable = 0
  @Published public private(set) var daxIqCapacity = 0
  @Published public private(set) var enforcePrivateIpEnabled = false
  @Published public private(set) var extPresent = false
  @Published public private(set) var filterCwAutoEnabled = false
  @Published public private(set) var filterDigitalAutoEnabled = false
  @Published public private(set) var filterVoiceAutoEnabled = false
  @Published public private(set) var filterCwLevel = 0
  @Published public private(set) var filterDigitalLevel = 0
  @Published public private(set) var filterVoiceLevel = 0
  @Published public private(set) var fpgaMbVersion = ""
  @Published public private(set) var freqErrorPpb = 0
  @Published public private(set) var frontSpeakerMute = false
  @Published public private(set) var fullDuplexEnabled = false
  @Published public private(set) var gateway = ""
  @Published public private(set) var gpsPresent = false
  @Published public private(set) var gpsdoPresent = false
  @Published public private(set) var headphoneGain = 0
  @Published public private(set) var headphoneMute = false
  @Published public private(set) var ipAddress = ""
  @Published public private(set) var lineoutGain = 0
  @Published public private(set) var lineoutMute = false
  @Published public private(set) var localPtt = false
  @Published public private(set) var location = ""
  @Published public private(set) var locked = false
  @Published public private(set) var macAddress = ""
  @Published public private(set) var micList = [MicrophonePort]()
  @Published public internal(set) var mox = false
  @Published public private(set) var muteLocalAudio = false
  @Published public private(set) var netmask = ""
  @Published public private(set) var nickname = ""
  @Published public private(set) var numberOfScus = 0
  @Published public private(set) var numberOfSlices = 0
  @Published public private(set) var numberOfTx = 0
  @Published public private(set) var oscillator = ""
  @Published public private(set) var picDecpuVersion = ""
  @Published public private(set) var program = ""
  @Published public private(set) var psocMbPa100Version = ""
  @Published public private(set) var psocMbtrxVersion = ""
  @Published public private(set) var radioAuthenticated = false
  @Published public private(set) var radioModel = ""
  @Published public private(set) var radioOptions = ""
  @Published public private(set) var region = ""
  @Published public private(set) var radioScreenSaver = ""
  @Published public private(set) var remoteOnEnabled = false
  @Published public private(set) var rttyMark = 0
  @Published public private(set) var serverConnected = false
  @Published public private(set) var setting = ""
  @Published public private(set) var sliceList = [SliceId]()
  @Published public private(set) var smartSdrMB = ""
  @Published public private(set) var snapTuneEnabled = false
  @Published public private(set) var softwareVersion = ""
  @Published public private(set) var startCalibration = false
  @Published public private(set) var state = ""
  @Published public private(set) var staticGateway = ""
  @Published public private(set) var staticIp = ""
  @Published public private(set) var staticNetmask = ""
  @Published public private(set) var station = ""
  @Published public private(set) var tnfsEnabled = false
  @Published public private(set) var tcxoPresent = false
  @Published public private(set) var uptime = 0


  enum FilterSharpnessTokens: String {
    case cw
    case digital
    case voice
    case autoLevel                = "auto_level"
    case level
  }
  enum InfoTokens: String {
    case atuPresent               = "atu_present"
    case callsign
    case chassisSerial            = "chassis_serial"
    case gateway
    case gps
    case ipAddress                = "ip"
    case location
    case macAddress               = "mac"
    case model
    case netmask
    case name
    case numberOfScus             = "num_scu"
    case numberOfSlices           = "num_slice"
    case numberOfTx               = "num_tx"
    case options
    case region
    case screensaver
    case softwareVersion          = "software_ver"
  }
  enum StatusTokens: String {
    case amplifier
    case atu
    case client
    case cwx
    case display
    case eq
    case file
    case gps
    case interlock
    case memory
    case meter
    case mixer
    case profile
    case radio
    case slice
    case stream
    case tnf
    case transmit
    case turf
    case usbCable                 = "usb_cable"
    case wan
    case waveform
    case xvtr
  }
  enum OscillatorTokens: String {
    case extPresent               = "ext_present"
    case gpsdoPresent             = "gpsdo_present"
    case locked
    case setting
    case state
    case tcxoPresent              = "tcxo_present"
  }
  enum RadioSubTokens: String {
    case filterSharpness          = "filter_sharpness"
    case staticNetParams          = "static_net_params"
    case oscillator
  }
  enum RadioTokens: String {
    case backlight
    case bandPersistenceEnabled   = "band_persistence_enabled"
    case binauralRxEnabled        = "binaural_rx"
    case calFreq                  = "cal_freq"
    case callsign
    case daxIqAvailable           = "daxiq_available"
    case daxIqCapacity            = "daxiq_capacity"
    case enforcePrivateIpEnabled  = "enforce_private_ip_connections"
    case freqErrorPpb             = "freq_error_ppb"
    case frontSpeakerMute         = "front_speaker_mute"
    case fullDuplexEnabled        = "full_duplex_enabled"
    case headphoneGain            = "headphone_gain"
    case headphoneMute            = "headphone_mute"
    case lineoutGain              = "lineout_gain"
    case lineoutMute              = "lineout_mute"
    case muteLocalAudio           = "mute_local_audio_when_remote"
    case nickname
    case panadapters
    case pllDone                  = "pll_done"
    case radioAuthenticated       = "radio_authenticated"
    case remoteOnEnabled          = "remote_on_enabled"
    case rttyMark                 = "rtty_mark_default"
    case serverConnected          = "server_connected"
    case slices
    case snapTuneEnabled          = "snap_tune_enabled"
    case tnfsEnabled              = "tnf_enabled"
  }
  enum StaticNetTokens: String {
    case gateway
    case ip
    case netmask
  }
  enum VersionTokens: String {
    case fpgaMb                   = "fpga-mb"
    case psocMbPa100              = "psoc-mbpa100"
    case psocMbTrx                = "psoc-mbtrx"
    case smartSdrMB               = "smartsdr-mb"
    case picDecpu                 = "pic-decpu"
  }

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
  // MARK: - Private properties

  private let _appName: String
  private var _clientId: String?
  private let _domain: String
  private let _connectionType: ConnectionType
  private var _clientInitialized = false
  private var _radioInitialized = false
  private var _params: ConnectionParams!
  private let _parseQ = DispatchQueue(label: "Radio.parseQ", qos: .userInteractive)
  private var _pinger: Pinger?
  private var _command: TcpCommand
  private var _stream: UdpStream
  private var _cancellable: AnyCancellable?
  let _log = LogProxy.sharedInstance.log
  private var _packet: Packet
  private var _replyHandlers = [SequenceNumber: ReplyTuple]()
  private var _lowBandwidthConnect = false
  private var _lowBandwidthDax = false
  private var _stationName: String?
  private var _programName: String?

  private let kVersionSupported = Version("3.2.34")

  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ packet: Packet, connectionType: ConnectionType, command: TcpCommand, stream: UdpStream, stationName: String? = nil, programName: String? = nil, lowBandwidthConnect: Bool = false, lowBandwidthDax: Bool = false) {
    _packet = packet
    _connectionType = connectionType
    _command = command
    _stream = stream
    _lowBandwidthConnect = lowBandwidthConnect
    _lowBandwidthDax = lowBandwidthDax
    _stationName = stationName
    _programName = programName

    let bundleIdentifier = Bundle.main.bundleIdentifier ?? "net.k3tzr.Radio"
    let separator = bundleIdentifier.lastIndex(of: ".")!
    _appName = String(bundleIdentifier.suffix(from: bundleIdentifier.index(separator, offsetBy: 1)))
    _domain = String(bundleIdentifier.prefix(upTo: separator))

    // initialize the static models (only one of each is ever created)
//    atu = Atu()
//    cwx = Cwx()
//    gps = Gps()
    interlock = Interlock()
//    netCwStream = NetCwStream()
//    transmit = Transmit()
//    waveform = Waveform()

    // initialize Equalizers
    equalizers[.rxsc] = Equalizer(Equalizer.EqType.rxsc.rawValue)
    equalizers[.txsc] = Equalizer(Equalizer.EqType.txsc.rawValue)

    _cancellable = command.commandPublisher
      .receive(on: _parseQ)
      .sink { [weak self] msg in
        self?.receivedMessage(msg)
      }
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
    if _command.connect(packet) {
      checkVersion()
      return true
    }
    // connection failed
    return false
  }


  /// Send a command to the Radio (hardware)
  /// - Parameters:
  ///   - command:        a Command String
  ///   - flag:           use "D"iagnostic form
  ///   - callback:       a callback function (if any)
  public func send(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil) {

      // tell the TcpManager to send the command
      let sequenceNumber = _command.send(command, diagnostic: flag)

      // register to be notified when reply received
      addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Parse  Command messages from the Radio
  ///
  /// - Parameter msg:        the Message String
  private func receivedMessage(_ msg: TcpMessage) {
    // get all except the first character
    let suffix = String(msg.text.dropFirst())

    // switch on the first character of the text
    switch msg.text[msg.text.startIndex] {

    case "H", "h":  connectionHandle = suffix.handle ; _log("Radio: connectionHandle = \(connectionHandle?.hex ?? "nil")", .debug, #function, #file, #line)
    case "M", "m":  parseMessage( msg.text.dropFirst() )
    case "R", "r":  parseReply( msg.text.dropFirst() )
    case "S", "s":  parseStatus( msg.text.dropFirst() )
    case "V", "v":  hardwareVersion = suffix ; _log("Radio: hardwareVersion = \(hardwareVersion ?? "unknown")", .debug, #function, #file, #line)
    default:        _log("Radio: unexpected message = \(msg)", .warning, #function, #file, #line)
    }
  }

  /// Parse a Message.
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  private func parseMessage(_ msg: Substring) {
    // separate it into its components
    let components = msg.components(separatedBy: "|")

    // ignore incorrectly formatted messages
    if components.count < 2 {
      _log("Radio: incomplete message = c\(msg)", .warning, #function, #file, #line)
      return
    }
    let msgText = components[1]

    // log it
    _log("Radio: message = \(msgText)", flexErrorLevel(errorCode: components[0]), #function, #file, #line)

    // FIXME: Take action on some/all errors?
  }

  private func parseReply(_ msg: Substring) {

    // TODO: this is a stub for now
  }

  /// Parse a Status
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  private func parseStatus(_ commandSuffix: Substring) {
    // separate it into its components ( [0] = <apiHandle>, [1] = <remainder> )
    let components = commandSuffix.components(separatedBy: "|")

    // ignore incorrectly formatted status
    guard components.count > 1 else {
      _log("Radio: incomplete status = c\(commandSuffix)", .warning, #function, #file, #line)
      return
    }
    // find the space & get the msgType
    let spaceIndex = components[1].firstIndex(of: " ")!
    let msgType = String(components[1][..<spaceIndex])

    // everything past the msgType is in the remainder
    let remainderIndex = components[1].index(after: spaceIndex)
    let remainder = String(components[1][remainderIndex...])

    // Check for unknown Message Types
    guard let token = StatusTokens(rawValue: msgType)  else {
      // log it and ignore the message
      _log("Radio: unknown status token = \(msgType)", .warning, #function, #file, #line)
      return
    }
    // Known Message Types, in alphabetical order
    switch token {

      //      case .amplifier:      Amplifier.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
      //      case .atu:            atu.parseProperties(remainder.keyValuesArray() )
      //      case .client:         parseClient(self, remainder.keyValuesArray(), !remainder.contains(Api.kDisconnected))
      //      case .cwx:            cwx.parseProperties(remainder.fix().keyValuesArray() )
      //      case .display:        parseDisplay(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
    case .eq:             Equalizer.parseStatus(self, remainder.keyValuesArray())
      //      case .file:           _log("Radio, unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
      //      case .gps:            gps.parseProperties(remainder.keyValuesArray(delimiter: "#") )
    case .interlock:      parseInterlock(self, remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
      //      case .memory:         Memory.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
      //      case .meter:          Meter.parseStatus(self, remainder.keyValuesArray(delimiter: "#"), !remainder.contains(Api.kRemoved))
      //      case .mixer:          _log("Radio, unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
      //      case .profile:        Profile.parseStatus(self, remainder.keyValuesArray(delimiter: "="))
    case .radio:          parseProperties(remainder.keyValuesArray())
      //      case .slice:          xLib6001.Slice.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kNotInUse))
      //      case .stream:         parseStream(self, remainder)
    case .tnf:            Tnf.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
      //      case .transmit:       parseTransmit(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
      //      case .turf:           _log("Radio, unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
      //      case .usbCable:       UsbCable.parseStatus(self, remainder.keyValuesArray())
      //      case .wan:            parseProperties(remainder.keyValuesArray())
      //      case .waveform:       waveform.parseProperties(remainder.keyValuesArray())
      //      case .xvtr:           Xvtr.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kNotInUse))
    default: _log("Radio: TODO, \(token) parsing NOT IMPLEMENTED", .warning, #function, #file, #line)
    }
    // is this status message the first for our handle?
    if !_clientInitialized && components[0].handle == connectionHandle {
      // YES, set the API state to finish the UDP initialization
      _clientInitialized = true
      updateState(to: .clientConnected(radio: self))
    }
  }

  /// Change the state of the API
  /// - Parameter newState: the new state
  public func updateState(to newState: RadioState) {
    radioState = newState

    switch radioState {

      // Connection -----------------------------------------------------------------------------
    case .tcpConnected (let host, let port):
      _log("Radio: TCP connected to \(host), port \(port)", .debug, #function, #file, #line)
//      NC.post(.tcpDidConnect, object: nil)

      if _packet.source == .smartlink {
        _log("Radio: Api Validate Wan handle = \(_packet.wanHandle)", .debug, #function, #file, #line)
        send("wan validate handle=" + _packet.wanHandle, replyTo: wanValidateReplyHandler)

      } else {
        // bind a UDP port for the Streams
        if _stream.bind(_packet) == false { _command.disconnect() }

        // FIXME: clientHandle is not used by bind????
      }

    case .wanHandleValidated (let success):
      if success {
        _log("Radio: Api Wan handle validated", .debug, #function, #file, #line)
        if _stream.bind(_packet) == false { _command.disconnect() }
      } else {
        _log("Radio: Api Wan handle validation FAILED", .debug, #function, #file, #line)
        _command.disconnect()
      }

    case .udpBound (let receivePort, let sendPort):
      _log("Radio: UDP bound, receive port = \(receivePort), send port = \(sendPort)", .debug, #function, #file, #line)

      // if a Wan connection, register
      if _packet.source == .smartlink { _stream.register(clientHandle: connectionHandle) }

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

  /// Add a Reply Handler for a specific Sequence/Command
  ///   executes on the parseQ
  ///
  /// - Parameters:
  ///   - sequenceId:     sequence number of the Command
  ///   - replyTuple:     a Reply Tuple
  private func addReplyHandler(_ seqNumber: UInt, replyTuple: ReplyTuple) {
      // add the handler
      replyHandlers[seqNumber] = replyTuple
  }

  /// executed after an IP Address has been obtained
  private func connectionCompletion() {
    _log("Radio: connectionCompletion for \(_packet.nickname)", .debug, #function, #file, #line)
    sendCommands()
    send("client udpport " + "\(_stream.sendPort)")

    if pingerEnabled {
      // start pinging the Radio
      _pinger = Pinger(radio: self, command: _command, nickname: _packet.nickname)
    }


//      _log("Radio: connectionCompletion for \(radio.nickname)\(_params.pendingDisconnect != .none ? " (Pending Disconnection)" : "")", .debug, #function, #file, #line)
//
//      // send the initial commands if a normal connection
//      if _params.pendingDisconnect == .none { sendCommands(to: radio) }
//
//      // set the UDP port for a Local connection
//      if !radio.isWan { send("client udpport " + "\(udp.sendPort)") }
//
//      // start pinging (if enabled)
//      if _params.pendingDisconnect == .none { if pingerEnabled { _pinger = Pinger(tcpManager: tcp) }}
//
//      // ask for a CW stream (if requested)
//      if _params.pendingDisconnect == .none { if _params.needsCwStream { radio.requestNetCwStream() } }
//
//      // TCP & UDP connections established
//      NC.post(.clientDidConnect, object: radio as Any?)
//
//      // handle any pending disconnection
//      disconnectAsNeeded(_params)
  }

  // ----------------------------------------------------------------------------
  // MARK: - ReplyHandlers

  /// Process the Reply to a command, reply format: <value>,<value>,...<value>
  ///   executes on the parseQ
  ///
  /// - Parameters:
  ///   - command:        the original command
  ///   - seqNum:         the Sequence Number of the original command
  ///   - responseValue:  the response value
  ///   - reply:          the reply
  public func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) {
    guard responseValue == kNoError else {

      // ignore non-zero reply from "client program" command
      if !command.hasPrefix("client program ") {
        // Anything other than 0 is an error, log it and ignore the Reply
        let errorLevel = flexErrorLevel(errorCode: responseValue)
        _log("Radio, reply to c\(sequenceNumber), \(command): non-zero reply \(responseValue), \(flexErrorString(errorCode: responseValue))", errorLevel, #function, #file, #line)
      }
      return
    }

    // which command?
    switch command {

    case "client gui":    parseGuiReply( reply.keyValuesArray() )         // (V3 only)
    case "slice list":    DispatchQueue.main.async { [self] in sliceList = reply.valuesArray().compactMap {$0.objectId} }

    case "ant list":      DispatchQueue.main.async { [self] in antennaList = reply.valuesArray( delimiter: "," ) }
    case "info":          parseInfoReply( (reply.replacingOccurrences(of: "\"", with: "")).keyValuesArray(delimiter: ",") )
    case "mic list":      DispatchQueue.main.async { [self] in micList = reply.valuesArray(  delimiter: "," ) }
    case "radio uptime":  DispatchQueue.main.async { [self] in uptime = Int(reply) ?? 0 }
    case "version":       parseVersionReply( reply.keyValuesArray(delimiter: "#") )
    default:              break
    }
  }
  /// Parse an Interlock status message
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - radio:          the current Radio class
  ///   - properties:     a KeyValuesArray
  ///   - inUse:          false = "to be deleted"
  private func parseInterlock(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
      // is it a Band Setting?
      if properties[0].key == "band" {
          // YES, drop the "band", pass it to BandSetting
          BandSetting.parseStatus(self, Array(properties.dropFirst()), inUse )

      } else {
          // NO, pass it to Interlock
          interlock.parseProperties(self, properties)
      }
  }

  /// Parse the Reply to an Info command
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - properties:          a KeyValuesArray
  private func parseInfoReply(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = InfoTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Radio, unknown info token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {

      case .atuPresent:       atuPresent = property.value.bValue
      case .callsign:         callsign = property.value
      case .chassisSerial:    chassisSerial = property.value
      case .gateway:          gateway = property.value
      case .gps:              gpsPresent = (property.value != "Not Present")
      case .ipAddress:        ipAddress = property.value
      case .location:         location = property.value
      case .macAddress:       macAddress = property.value
      case .model:            radioModel = property.value
      case .netmask:          netmask = property.value
      case .name:             nickname = property.value
      case .numberOfScus:     numberOfScus = property.value.iValue
      case .numberOfSlices:   numberOfSlices = property.value.iValue
      case .numberOfTx:       numberOfTx = property.value.iValue
      case .options:          radioOptions = property.value
      case .region:           region = property.value
      case .screensaver:      radioScreenSaver = property.value
      case .softwareVersion:  softwareVersion = property.value
      }
    }
  }
  /// Parse the Reply to a Client Gui command,
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - properties:          a KeyValuesArray
  private func parseGuiReply(_ properties: KeyValuesArray) {
    // only v3 returns a Client Id
    for property in properties {
      // save the returned ID
      boundClientId = property.key
      break
    }
  }

  /// Parse the Reply to a Version command, reply format: <key=value>#<key=value>#...<key=value>
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - properties:          a KeyValuesArray
  private func parseVersionReply(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = VersionTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Radio, unknown version token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {

      case .smartSdrMB:   smartSdrMB = property.value
      case .picDecpu:     picDecpuVersion = property.value
      case .psocMbTrx:    psocMbtrxVersion = property.value
      case .psocMbPa100:  psocMbPa100Version = property.value
      case .fpgaMb:       fpgaMbVersion = property.value
      }
    }
  }
  /// Reply handler for the "wan validate" command
  /// - Parameters:
  ///   - command:                a Command string
  ///   - seqNum:                 the Command's sequence number
  ///   - responseValue:          the response contained in the Reply to the Command
  ///   - reply:                  the descriptive text contained in the Reply to the Command
  private func wanValidateReplyHandler(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    // return status
    updateState(to: .wanHandleValidated(success: responseValue == kNoError))
  }

  /// Send commands to configure the connection
  ///
  private func sendCommands() {

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

  /// Determine if the Radio Firmware version is compatable with the API version
  private func checkVersion() {
      // get the Radio Version
    let radioVersion = Version(softwareVersion)

      if kVersionSupported < radioVersion  {
          _log("Api Radio may need to be downgraded: Radio version = \(radioVersion.longString), API supports version = \(kVersionSupported.string)", .warning, #function, #file, #line)
//          NC.post(.radioDowngrade, object: (apiVersion: kVersionSupported.string, radioVersion: radioVersion.string))
      }
  }
}

extension Radio {
  /// Parse a Radio status message
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  func parseProperties(_ properties: KeyValuesArray) {
    // separate by category
    if let category = RadioSubTokens(rawValue: properties[0].key) {
      // drop the first property
      let adjustedProperties = Array(properties[1...])

      switch category {

      case .filterSharpness:  parseFilterProperties( adjustedProperties )
      case .staticNetParams:  parseStaticNetProperties( adjustedProperties )
      case .oscillator:       parseOscillatorProperties( adjustedProperties )
      }

    } else {
      // process each key/value pair, <key=value>
      for property in properties {
        // Check for Unknown Keys
        guard let token = RadioTokens(rawValue: property.key)  else {
          // log it and ignore the Key
          _log("Radio, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
          continue
        }
        // Known tokens, in alphabetical order
        switch token {

        case .backlight:                backlight = property.value.iValue
        case .bandPersistenceEnabled:   bandPersistenceEnabled = property.value.bValue
        case .binauralRxEnabled:        binauralRxEnabled = property.value.bValue
        case .calFreq:                  calFreq = property.value.dValue
        case .callsign:                 callsign = property.value
        case .daxIqAvailable:           daxIqAvailable = property.value.iValue
        case .daxIqCapacity:            daxIqCapacity = property.value.iValue
        case .enforcePrivateIpEnabled:  enforcePrivateIpEnabled = property.value.bValue
        case .freqErrorPpb:             freqErrorPpb = property.value.iValue
        case .fullDuplexEnabled:        fullDuplexEnabled = property.value.bValue
        case .frontSpeakerMute:         frontSpeakerMute = property.value.bValue
        case .headphoneGain:            headphoneGain = property.value.iValue
        case .headphoneMute:            headphoneMute = property.value.bValue
        case .lineoutGain:              lineoutGain = property.value.iValue
        case .lineoutMute:              lineoutMute = property.value.bValue
        case .muteLocalAudio:           muteLocalAudio = property.value.bValue
        case .nickname:                 nickname = property.value
        case .panadapters:              availablePanadapters = property.value.iValue
        case .pllDone:                  startCalibration = property.value.bValue
        case .radioAuthenticated:       radioAuthenticated = property.value.bValue
        case .remoteOnEnabled:          remoteOnEnabled = property.value.bValue
        case .rttyMark:                 rttyMark = property.value.iValue
        case .serverConnected:          serverConnected = property.value.bValue
        case .slices:                   availableSlices = property.value.iValue
        case .snapTuneEnabled:          snapTuneEnabled = property.value.bValue
        case .tnfsEnabled:              tnfsEnabled = property.value.bValue
        }
      }
    }
    // is the Radio initialized?
    if !_radioInitialized {
      // YES, notify all observers
      _radioInitialized = true

      // TODO: ???
      //      NC.post(.radioHasBeenAdded, object: self as Any?)
    }
  }

  /// Parse a Filter Properties status message
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  private func parseFilterProperties(_ properties: KeyValuesArray) {
    var cw = false
    var digital = false
    var voice = false

    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = FilterSharpnessTokens(rawValue: property.key.lowercased())  else {
        // log it and ignore the Key
        _log("Radio, unknown filter token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {

      case .cw:       cw = true
      case .digital:  digital = true
      case .voice:    voice = true

      case .autoLevel:
        if cw       { filterCwAutoEnabled = property.value.bValue ; cw = false }
        if digital  { filterDigitalAutoEnabled = property.value.bValue ; digital = false }
        if voice    { filterVoiceAutoEnabled = property.value.bValue ; voice = false }
      case .level:
        if cw       { filterCwLevel = property.value.iValue }
        if digital  { filterDigitalLevel = property.value.iValue  }
        if voice    { filterVoiceLevel = property.value.iValue }
      }
    }
  }

  /// Parse a Static Net Properties status message
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  private func parseStaticNetProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = StaticNetTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Radio, unknown static token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {

      case .gateway:  staticGateway = property.value
      case .ip:       staticIp = property.value
      case .netmask:  staticNetmask = property.value
      }
    }
  }

  /// Parse an Oscillator Properties status message
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  private func parseOscillatorProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = OscillatorTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Radio, unknown oscillator token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {

      case .extPresent:   extPresent = property.value.bValue
      case .gpsdoPresent: gpsdoPresent = property.value.bValue
      case .locked:       locked = property.value.bValue
      case .setting:      setting = property.value
      case .state:        state = property.value
      case .tcxoPresent:  tcxoPresent = property.value.bValue
      }
    }
  }

}
