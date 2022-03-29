//
//  ApiCore.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 11/24/21.
//

import Combine
import ComposableArchitecture
import Dispatch
import SwiftUI

import LanDiscovery
import WanDiscovery
import Login
import LogViewer
import Picker
import Radio
import RemoteViewer
import Shared
import TcpCommands
import UdpStreams
import XCGWrapper
import ClientStatus

import simd

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

public typealias Logger = (PassthroughSubject<LogEntry, Never>, LogLevel) -> Void

public struct TcpMessage: Equatable, Identifiable {
  public var id = UUID()
  var direction: TcpMessageDirection
  var text: String
  var color: Color
  var timeInterval: TimeInterval
}

public struct DefaultConnection: Codable, Equatable {
  public init(_ selection: PickerSelection) {
    self.source = selection.packet.source.rawValue
    self.serial = selection.packet.serial
    self.station = selection.station
  }
  var source: String
  var serial: String
  var station: String?

  enum CodingKeys: String, CodingKey {
    case source
    case serial
    case station
  }

  public static func == (lhs: DefaultConnection, rhs: DefaultConnection) -> Bool {
    guard lhs.source == rhs.source else { return false }
    guard lhs.serial == rhs.serial else { return false }
    guard lhs.station == rhs.station else { return false }
    return true
  }
}

public enum ConnectionMode: String {
  case both
  case local
  case none
  case smartlink
}

public enum ViewType: Equatable {
  case api
  case log
  case remote
}

public enum ObjectsFilter: String, CaseIterable {
  case core
  case coreNoMeters = "core w/o meters"
  case amplifiers
  case bandSettings = "band settings"
  case interlock
  case memories
  case meters
  case streams
  case transmit
  case tnfs
  case waveforms
  case xvtrs
}

public enum MessagesFilter: String, CaseIterable {
  case all
  case prefix
  case includes
  case excludes
  case command
  case status
  case reply
  case S0
}

public struct MeterState: Equatable {
  public var value: Float
  public var id: MeterId
  public var forceUpdate = false
}

// ----------------------------------------------------------------------------
// MARK: - State, Actions & Environment

public struct ApiState: Equatable {  

  public init(
    clearOnConnect: Bool = UserDefaults.standard.bool(forKey: "clearOnConnect"),
    clearOnDisconnect: Bool  = UserDefaults.standard.bool(forKey: "clearOnDisconnect"),
    clearOnSend: Bool  = UserDefaults.standard.bool(forKey: "clearOnSend"),
    connectionMode: ConnectionMode = ConnectionMode(rawValue: UserDefaults.standard.string(forKey: "connectionMode") ?? "both") ?? .both,
    defaultConnection: DefaultConnection? = getDefaultConnection(),
    fontSize: CGFloat = UserDefaults.standard.double(forKey: "fontSize") == 0 ? 12 : UserDefaults.standard.double(forKey: "fontSize"),
    isGui: Bool = UserDefaults.standard.bool(forKey: "isGui"),
    messagesFilterBy: MessagesFilter = MessagesFilter(rawValue: UserDefaults.standard.string(forKey: "messagesFilterBy") ?? "all") ?? .all,
    messagesFilterByText: String = UserDefaults.standard.string(forKey: "messagesFilterByText") ?? "",
    objectsFilterBy: ObjectsFilter = ObjectsFilter(rawValue: UserDefaults.standard.string(forKey: "objectsFilterBy") ?? "core") ?? .core,
    radio: Radio? = nil,
    showPings: Bool = UserDefaults.standard.bool(forKey: "showPings"),
    showTimes: Bool = UserDefaults.standard.bool(forKey: "showTimes"),
    smartlinkEmail: String = UserDefaults.standard.string(forKey: "smartlinkEmail") ?? ""
  )
  {
    self.clearOnConnect = clearOnConnect
    self.clearOnDisconnect = clearOnDisconnect
    self.clearOnSend = clearOnSend
    self.connectionMode = connectionMode
    self.defaultConnection = defaultConnection
    self.fontSize = fontSize
    self.isGui = isGui
    self.messagesFilterBy = messagesFilterBy
    self.messagesFilterByText = messagesFilterByText
    self.objectsFilterBy = objectsFilterBy
    self.radio = radio
    self.showPings = showPings
    self.showTimes = showTimes
    self.smartlinkEmail = smartlinkEmail
  }

  // State held in User Defaults
  public var clearOnConnect: Bool { didSet { UserDefaults.standard.set(clearOnConnect, forKey: "clearOnConnect") } }
  public var clearOnDisconnect: Bool { didSet { UserDefaults.standard.set(clearOnDisconnect, forKey: "clearOnDisconnect") } }
  public var clearOnSend: Bool { didSet { UserDefaults.standard.set(clearOnSend, forKey: "clearOnSend") } }
  public var connectionMode: ConnectionMode { didSet { UserDefaults.standard.set(connectionMode.rawValue, forKey: "connectionMode") } }
  public var defaultConnection: DefaultConnection? { didSet { setDefaultConnection(defaultConnection) } }
  public var fontSize: CGFloat { didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") } }
  public var isGui: Bool { didSet { UserDefaults.standard.set(isGui, forKey: "isGui") } }
  public var messagesFilterBy: MessagesFilter { didSet { UserDefaults.standard.set(messagesFilterBy.rawValue, forKey: "messagesFilterBy") } }
  public var messagesFilterByText: String { didSet { UserDefaults.standard.set(messagesFilterByText, forKey: "messagesFilterByText") } }
  public var objectsFilterBy: ObjectsFilter { didSet { UserDefaults.standard.set(objectsFilterBy.rawValue, forKey: "objectsFilterBy") } }
  public var showPings: Bool { didSet { UserDefaults.standard.set(showPings, forKey: "showPings") } }
  public var showTimes: Bool { didSet { UserDefaults.standard.set(showTimes, forKey: "showTimes") } }
  public var smartlinkEmail: String { didSet { UserDefaults.standard.set(smartlinkEmail, forKey: "smartlinkEmail") } }
  
  // normal state
  public var alert: AlertState<ApiAction>?
  public var clearNow = false
  public var commandToSend = ""
  public var packetCollection: PacketCollection?
  public var lanListener: LanListener?
  public var wanListener: WanListener?
  public var filteredMessages = IdentifiedArrayOf<TcpMessage>()
  public var forceWanLogin = false
  public var loginState: LoginState? = nil
  public var messages = IdentifiedArrayOf<TcpMessage>()
  public var pickerState: PickerState? = nil
  public var radio: Radio?
  public var reverseLog = false
  public var tcp = Tcp()
  public var viewType: ViewType = .api
  
  public var cancellables = Set<AnyCancellable>()
  public var forceUpdate = false
  
  public var objects = Objects.sharedInstance
  public var clientState: ClientState?
  public var pendingWanSelection: PickerSelection?
}

public enum ApiAction: Equatable {
  // initialization
  case onAppear

  // UI controls
  case apiViewButton
  case clearDefaultButton
  case clearNowButton
  case commandTextField(String)
  case connectionModePicker(ConnectionMode)
  case fontSizeStepper(CGFloat)
  case logViewButton
  case messagesPicker(MessagesFilter)
  case messagesFilterTextField(String)
  case objectsPicker(ObjectsFilter)
  case remoteViewButton
  case sendButton
  case startStopButton
  case toggle(WritableKeyPath<ApiState, Bool>)
 
  // subview/sheet/alert related
  case alertDismissed
  case clientAction(ClientAction)
  case loginAction(LoginAction)
  case pickerAction(PickerAction)
  
  // Effects related
  case cancelEffects
  case checkConnectionStatus(PickerSelection)
  case clientChangeReceived(ClientUpdate)
  case finishInitialization
  case logAlertReceived(LogEntry)
  case meterReceived(Meter)
  case openSelection(PickerSelection)
  case packetChangeReceived(PacketUpdate)
  case tcpMessage(TcpMessage)
  case wanStatus(WanStatus)

}

public struct ApiEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    logger: @escaping Logger = { _ = XCGWrapper($0, logLevel: $1) }
  )
  {
    self.queue = queue
    self.logger = logger
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var logger: Logger
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

// swiftlint:disable trailing_closure
public let apiReducer = Reducer<ApiState, ApiAction, ApiEnvironment>.combine(
  clientReducer
    .optional()
    .pullback(
      state: \ApiState.clientState,
      action: /ApiAction.clientAction,
      environment: { _ in ClientEnvironment() }
    ),
  loginReducer
    .optional()
    .pullback(
      state: \ApiState.loginState,
      action: /ApiAction.loginAction,
      environment: { _ in LoginEnvironment() }
    ),
  pickerReducer
    .optional()
    .pullback(
      state: \ApiState.pickerState,
      action: /ApiAction.pickerAction,
      environment: { _ in PickerEnvironment() }
    ),
  Reducer { state, action, environment in
            
    switch action {      
      // ----------------------------------------------------------------------------
      // MARK: - Initialization
      
    case .onAppear:
      // if the first time, start various effects
      if state.packetCollection == nil {
        // instantiate the collection
        state.packetCollection = PacketCollection.sharedInstance
        // instantiate the Logger,
        _ = environment.logger(LogProxy.sharedInstance.logPublisher, .debug)
        // start subscriptions
        return .merge(
          subscribeToPackets(),
          subscribeToWan(),
          subscribeToSent(state.tcp),
          subscribeToReceived(state.tcp),
          subscribeToLogAlerts(),
          Effect(value: .finishInitialization))
      }
      return .none

    case .finishInitialization:
      // needed when coming from other than .onAppear
      state.lanListener?.stop()
      state.lanListener = nil
      state.wanListener?.stop()
      state.wanListener = nil

      switch state.connectionMode {
      case .local:
        state.packetCollection?.removePackets(ofType: .smartlink)
        state.lanListener = LanListener()
        state.lanListener!.start()
      case .smartlink:
        state.packetCollection?.removePackets(ofType: .local)
        state.wanListener = WanListener()
        if state.forceWanLogin || state.wanListener!.start(state.smartlinkEmail) == false {
          state.loginState = LoginState(heading: "Smartlink Login required", email: state.smartlinkEmail)
        }
      case .both:
        state.lanListener = LanListener()
        state.lanListener!.start()
        state.wanListener = WanListener()
        if state.forceWanLogin || state.wanListener!.start(state.smartlinkEmail) == false {
          state.loginState = LoginState(heading: "Smartlink Login required", email: state.smartlinkEmail)
        }
      case .none:
        state.packetCollection?.removePackets(ofType: .local)
        state.packetCollection?.removePackets(ofType: .smartlink)
      }
      if state.objectsFilterBy == .core || state.objectsFilterBy == .meters {
        return subscribeToMeters()
      }
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - ApiView UI actions
      
    case .apiViewButton:
      state.viewType = .api
      return .none
      
    case .clearDefaultButton:
      state.defaultConnection = nil
      return .none
      
    case .clearNowButton:
      state.messages.removeAll()
      state.filteredMessages.removeAll()
      return .none
      
    case .commandTextField(let text):
      state.commandToSend = text
      return .none
      
    case .connectionModePicker(let mode):
      state.connectionMode = mode
      return Effect(value: .finishInitialization)

    case .fontSizeStepper(let size):
      state.fontSize = size
      return .none
      
    case .logViewButton:
      state.viewType = .log
      return .none
      
    case .messagesPicker(let filter):
      state.messagesFilterBy = filter
      // re-filter
      state.filteredMessages = filterMessages(state, state.messagesFilterBy, state.messagesFilterByText)
      return .none

    case .messagesFilterTextField(let text):
      state.messagesFilterByText = text
      // re-filter
      state.filteredMessages = filterMessages(state, state.messagesFilterBy, state.messagesFilterByText)
      return .none

    case .objectsPicker(let newFilterBy):
      let prevObjectsFilterBy = state.objectsFilterBy
      state.objectsFilterBy = newFilterBy
      
      switch (prevObjectsFilterBy, newFilterBy) {
      case (.core, .meters), (.meters, .core):  return .none
      case (.core, _), (.meters, _):            return .cancel(id: MeterSubscriptionId())
      case (_, .core), (_, .meters):            return subscribeToMeters()
      default:                                  return .none
      }
      
    case .remoteViewButton:
      state.viewType = .remote
      return .none
      
    case .sendButton:
      _ = state.tcp.send(state.commandToSend)
      return .none
      
    case .startStopButton:
      // current state?
      if state.radio == nil {
        // NOT connected, check for a default
        // is there a default?
        if let selection = hasDefault(state) {
          // YES, is it Wan?
          if selection.packet.source == .smartlink {
            // YES, reply will generate a wanStatus action
            state.pendingWanSelection = selection
            state.wanListener!.sendWanConnectMessage(for: selection.packet.serial, holePunchPort: selection.packet.negotiatedHolePunchPort)
            return .none

          } else {
            // NO, check for other connections
            return Effect(value: .checkConnectionStatus(selection))
          }
          
        } else {
          // NO, or failed to find a match, open the Picker
          state.pickerState = PickerState(connectionType: state.isGui ? .gui : .nonGui)
          return .none
        }
        
      } else {
        // CONNECTED, disconnect
        state.radio?.disconnect()
        state.radio = nil
        if state.clearOnDisconnect {
          state.messages.removeAll()
          state.filteredMessages.removeAll()
        }
        return .none
      }
      
    case .toggle(let keyPath):
      // handles all buttons with a Bool state
      state[keyPath: keyPath].toggle()
      if keyPath == \.forceWanLogin && state.forceWanLogin {
        return Effect(value: .finishInitialization)
      }
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by the picker (i.e. Picker -> ApiViewer)
      
    case .pickerAction(.cancelButton):
      // close the Picker sheet
      state.pickerState = nil
      return .none
      
    case .pickerAction(.connectButton(let selection)):
      // close the Picker sheet
      state.pickerState = nil
      
      if selection.packet.source == .smartlink {
        // reply will generate a wanStatus action
        state.pendingWanSelection = selection
        state.wanListener!.sendWanConnectMessage(for: selection.packet.serial, holePunchPort: selection.packet.negotiatedHolePunchPort)
        return .none

      } else {
        // check for other connections
        return Effect(value: .checkConnectionStatus(selection))
      }
      
    case .pickerAction(.defaultButton(let selection)):
      // set / reset the default connection
      if state.defaultConnection == nil {
        state.defaultConnection = DefaultConnection(selection)
      } else {
        state.defaultConnection = nil
      }
      return .none
      
    case .pickerAction(.testButton(let selection)):
      // send a Test request
      state.wanListener!.sendSmartlinkTest(selection.packet.serial) 
      // reply will generate a testResultReceived action
      return .none

    case .pickerAction(_):
      // IGNORE ALL OTHER picker actions
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by Client (i.e. Client -> ApiViewe)
      
    case .clientAction(.cancelButton):
      state.clientState = nil
      // additional processing upstream
      return .none

    case .clientAction(.connect(let selection, let disconnectHandle)):
      state.clientState = nil
      return Effect(value: .openSelection(PickerSelection(selection.packet, selection.station, disconnectHandle)))

 
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by Login (i.e. Login -> ApiViewer)

    case .loginAction(.cancelButton):
      state.loginState = nil
      return .none
      
    case .loginAction(.loginButton(let credentials)):
      state.loginState = nil
      state.smartlinkEmail = credentials.email
      if state.wanListener!.start(using: credentials) {
        state.forceWanLogin = false
      } else {
        state.alert = AlertState(title: TextState("Smartlink login failed"))
      }
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Action sent when an Alert is closed
      
    case .alertDismissed:
      state.alert = nil
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by long-running effects
                  
    case .cancelEffects:
      return .cancel(ids: LogAlertSubscriptionId(),
                     SentSubscriptionId(),
                     ReceivedSubscriptionId(),
                     MeterSubscriptionId())
      
    case .logAlertReceived(let logEntry):
      // a Warning or Error has been logged.
      // exit any sheet states
      state.pickerState = nil
      state.loginState = nil
      // return to the primary view
      state.viewType = .api
      // alert the user
      state.alert = .init(title: TextState(
                              """
                              \(logEntry.level == .warning ? "A Warning" : "An Error") was logged:
                              
                              \(logEntry.msg)
                              """
                              )
      )
      return .none
      
    case .tcpMessage(let message):
      // a TCP messages (either sent or received) has been captured
      // ignore sent "ping" messages unless showPings is true
      if message.direction == .sent && message.text.contains("ping") && state.showPings == false { return .none }
      // add the message to the collection
      state.messages.append(message)
      // re-filter
      state.filteredMessages = filterMessages(state, state.messagesFilterBy, state.messagesFilterByText)
      return .none

    case .meterReceived(let meter):
      state.forceUpdate.toggle()
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by other actions
      
    case .checkConnectionStatus(let selection):
      // are there any Gui connections?
      if state.isGui && selection.packet.guiClients.count > 0 {
        // YES, may need a disconnect, let the user choose
        state.clientState = ClientState(pickerSelection: selection)
        return .none

      } else {
        // NO, proceed to opening
        return Effect(value: .openSelection(selection))
      }

    case .openSelection(let selection):
      // instantiate a Radio object
      state.radio = Radio(selection.packet,
                          connectionType: state.isGui ? .gui : .nonGui,
                          command: state.tcp,
                          stream: Udp(),
                          stationName: "Api6000",
                          programName: "Api6000",
                          disconnectHandle: selection.disconnectHandle,
                          testerModeEnabled: true)
      // try to connect
      if state.radio!.connect(selection.packet) {
        // connected
        if state.clearOnConnect {
          state.messages.removeAll()
          state.filteredMessages.removeAll()
        }
      } else {
        // failed
        state.alert = AlertState(title: TextState("Failed to connect to Radio \(selection.packet.nickname)"))
      }
      return .none
    
    case .loginAction(.binding(_)):
      print("other binding")
      return .none
    
    case .packetChangeReceived(_):
      return .none
    
    case .clientChangeReceived(_):
      return .none
    
    case .wanStatus(let status):
      if state.pendingWanSelection != nil && status.type == .connect && status.wanHandle != nil {
          state.pendingWanSelection!.packet.wanHandle = status.wanHandle!
          // check for other connections
          return Effect(value: .checkConnectionStatus(state.pendingWanSelection!))
      }
      return .none
    }
  }
)
//  .debug("APIVIEWER ")


// ----------------------------------------------------------------------------
// MARK: - Helper methods

/// FIlter the Messages array
/// - Parameters:
///   - state:         the current ApiState
///   - filterBy:      the selected filter choice
///   - filterText:    the current filter text
/// - Returns:         a filtered array
func filterMessages(_ state: ApiState, _ filterBy: MessagesFilter, _ filterText: String) -> IdentifiedArrayOf<TcpMessage> {
  var filteredMessages = IdentifiedArrayOf<TcpMessage>()
  
  // re-filter messages
  switch (filterBy, filterText) {
    
  case (.all, _):        filteredMessages = state.messages
  case (.prefix, ""):    filteredMessages = state.messages
  case (.prefix, _):     filteredMessages = state.messages.filter { $0.text.localizedCaseInsensitiveContains("|" + filterText) }
  case (.includes, _):   filteredMessages = state.messages.filter { $0.text.localizedCaseInsensitiveContains(filterText) }
  case (.excludes, ""):  filteredMessages = state.messages
  case (.excludes, _):   filteredMessages = state.messages.filter { !$0.text.localizedCaseInsensitiveContains(filterText) }
  case (.command, _):    filteredMessages = state.messages.filter { $0.text.prefix(1) == "C" }
  case (.S0, _):         filteredMessages = state.messages.filter { $0.text.prefix(3) == "S0|" }
  case (.status, _):     filteredMessages = state.messages.filter { $0.text.prefix(1) == "S" && $0.text.prefix(3) != "S0|"}
  case (.reply, _):      filteredMessages = state.messages.filter { $0.text.prefix(1) == "R" }
  }
  return filteredMessages
}

/// Read the user defaults entry for a default connection and transform it into a DefaultConnection struct
/// - Returns:         a DefaultConnection struct or nil
public func getDefaultConnection() -> DefaultConnection? {
  if let defaultData = UserDefaults.standard.object(forKey: "defaultConnection") as? Data {
    let decoder = JSONDecoder()
    if let defaultConnection = try? decoder.decode(DefaultConnection.self, from: defaultData) {
      return defaultConnection
    } else {
      return nil
    }
  }
  return nil
}

/// Write the user defaults entry for a default connection using a DefaultConnection struct
/// - Parameter conn: a DefaultConnection struct  to be encoded and written to user defaults
func setDefaultConnection(_ conn: DefaultConnection?) {
  if conn == nil {
    UserDefaults.standard.removeObject(forKey: "defaultConnection")
  } else {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(conn) {
      UserDefaults.standard.set(encoded, forKey: "defaultConnection")
    } else {
      UserDefaults.standard.removeObject(forKey: "defaultConnection")
    }
  }
}

func hasDefault(_ state: ApiState) -> PickerSelection? {
  // is there a saved default?
  if let saved = state.defaultConnection {
    // YES, find a matching discovered packet
    for packet in state.packetCollection!.packets where saved.source == packet.source.rawValue && saved.serial == packet.serial {
      // found one
      return PickerSelection(packet, saved.station, nil)
    }
  }
  // NO default or failed to find a match
  return nil
}
