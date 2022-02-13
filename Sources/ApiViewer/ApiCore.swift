//
//  ApiCore.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 11/24/21.
//

import ComposableArchitecture
import Combine
import Dispatch
import SwiftUI

import Login
import Picker
import Discovery
import TcpCommands
import UdpStreams
import Radio
import XCGWrapper
import Shared
import LogViewer

public typealias Logger = (LogLevel) -> Void
public typealias Discoverer = () -> Void

public enum ViewType: Equatable {
  case api
  case log
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
  public var discovery: Discovery? = nil
  public var filteredMessages = IdentifiedArrayOf<TcpMessage>()
  public var forceWanLogin = false
  public var loginState: LoginState? = nil
  public var messages = IdentifiedArrayOf<TcpMessage>()
  public var pickerState: PickerState? = nil
  public var radio: Radio?
  public var reverse = false
  public var tcp = Tcp()
//  public var update = false
  public var viewType: ViewType = .api
  
  public var cancellables = Set<AnyCancellable>()
}

public enum ApiAction: Equatable {
  case onAppear

  // ApiView controls
  case apiViewButton
  case clearDefaultButton
  case clearNowButton
  case commandTextField(String)
  case connectionModePicker(ConnectionMode)
  case fontSizeStepper(CGFloat)
  case forceLoginButton
  case logViewButton
  case messagesPicker(MessagesFilter)
  case messagesFilterTextField(String)
  case objectsPicker(ObjectsFilter)
  case reverseButton
  case sendButton
  case startStopButton
  case toggleButton(WritableKeyPath<ApiState, Bool>)
  
  // sheet/alert related
  case alertDismissed
  case loginAction(LoginAction)
  case pickerAction(PickerAction)

  // Effects related
  case filterMessages(MessagesFilter, String)
  case checkForDefault
  case logAlert(LogEntry)
  case tcpAction(TcpMessage)
  case finishInitialization
  case cancelEffects
}

public struct ApiEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    logger: @escaping Logger = { _ = XCGWrapper($0) }
  )
  {
    self.queue = queue
    self.logger = logger
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var logger: Logger
}

// swiftlint:disable trailing_closure
public let apiReducer = Reducer<ApiState, ApiAction, ApiEnvironment>.combine(
  pickerReducer
    .optional()
    .pullback(
      state: \ApiState.pickerState,
      action: /ApiAction.pickerAction,
      environment: { _ in PickerEnvironment() }
    ),
  Reducer { state, action, environment in
    
    // ----------------------------------------------------------------------------
    // MARK: - Helper functions
    
    func listenForPackets(_ discovery: Discovery?) {
      guard discovery != nil else { return }
      state.alert = startStopLanListener(state.connectionMode, discovery: discovery!)
      
      if state.forceWanLogin {
        // show the Login sheet
        state.loginState = LoginState(email: state.smartlinkEmail)

      } else {
        let alert = startStopWanListener(state.connectionMode, discovery: discovery!, using: state.smartlinkEmail, forceLogin: state.forceWanLogin)
        if alert != nil {
          state.alert = alert
          // show the Login sheet
          state.loginState = LoginState(email: state.smartlinkEmail)
        }
      }
    }
            
    switch action {      
      // ----------------------------------------------------------------------------
      // MARK: - Initialization
      
    case .onAppear:
      // if the first time, start various effects
      if state.discovery == nil {
        // listen for log alerts, capture TCP messages (sent & received)
        return .merge(logAlerts(), sentMessages(state.tcp), receivedMessages(state.tcp), Effect(value: .finishInitialization))
      }
      return .none

    case .finishInitialization:
      // instantiate the Logger
      _ = environment.logger(.debug)
      // instantiate Discovery
      state.discovery = Discovery.sharedInstance
      // listen for broadcast packets
      listenForPackets(state.discovery)
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
      // reconfigure the listeners
      listenForPackets(state.discovery)
      return .none
      
    case .fontSizeStepper(let size):
      state.fontSize = size
      return .none
      
    case .forceLoginButton:
      // get the current mode
      let savedMode = state.connectionMode
      // stop all listeners
      state.connectionMode = .none
      listenForPackets(state.discovery)
      // set the force flag, restore the mode and restart listeners
      state.forceWanLogin = true
      state.connectionMode = savedMode
      listenForPackets(state.discovery)
      // turn off the force flag
      state.forceWanLogin = false
      return .none
      
    case .logViewButton:
      state.viewType = .log
      return .none
      
    case .messagesPicker(let filter):
      state.messagesFilterBy = filter
      // re-filter on change
      return Effect(value: .filterMessages(state.messagesFilterBy, state.messagesFilterByText))

    case .messagesFilterTextField(let text):
      state.messagesFilterByText = text
      // re-filter on change
      return Effect(value: .filterMessages(state.messagesFilterBy, state.messagesFilterByText))

    case .objectsPicker(let filterBy):
      state.objectsFilterBy = filterBy
      return.none
      
    case .reverseButton:
      state.reverse.toggle()
      return .none
      
    case .sendButton:
      _ = state.tcp.send(state.commandToSend)
      return .none
      
    case .startStopButton:
      // current state?
      if state.radio == nil {
        // NOT connected, check for a default
        return Effect(value: .checkForDefault)
        
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
      
    case .toggleButton(let keyPath):
      // handles all buttons with a Bool state
      state[keyPath: keyPath].toggle()
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by the picker (i.e. Picker -> ApiViewer)
      
    case .pickerAction(.cancelButton):
      // close the Picker sheet
      state.pickerState = nil
      return .none
      
    case .pickerAction(.openSelection(let selection)):
      // close the Picker sheet
      state.pickerState = nil
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
      
    case .pickerAction(.defaultButton(let selection)):
      // set / reset the default connection
      if state.defaultConnection == nil {
        state.defaultConnection = DefaultConnection(selection)
      } else {
        state.defaultConnection = nil
      }
      return .none
      
    case .pickerAction(_):
      // IGNORE ALL OTHER picker actions
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent upstream by Login (i.e. Login -> ApiViewer)

    case .loginAction(.cancelButton):
      state.loginState = nil
      return .none
      
    case .loginAction(.loginButton(let credentials)):
      state.loginState = nil
      state.smartlinkEmail = credentials.email
      state.alert = startWanListener(state.discovery!, using: credentials)
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Action sent when an Alert is closed
      
    case .alertDismissed:
      state.alert = nil
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Actions sent by other actions or publishers
            
    case .filterMessages(let filterBy, let filterText):
      // re-filter messages
      switch (filterBy, filterText) {
        
      case (.all, _):        state.filteredMessages = state.messages
      case (.prefix, ""):    state.filteredMessages = state.messages
      case (.prefix, _):     state.filteredMessages = state.messages.filter { $0.text.localizedCaseInsensitiveContains("|" + filterText) }
      case (.includes, _):   state.filteredMessages = state.messages.filter { $0.text.localizedCaseInsensitiveContains(filterText) }
      case (.excludes, ""):  state.filteredMessages = state.messages
      case (.excludes, _):   state.filteredMessages = state.messages.filter { !$0.text.localizedCaseInsensitiveContains(filterText) }
      case (.command, _):    state.filteredMessages = state.messages.filter { $0.text.prefix(1) == "C" }
      case (.S0, _):         state.filteredMessages = state.messages.filter { $0.text.prefix(3) == "S0|" }
      case (.status, _):     state.filteredMessages = state.messages.filter { $0.text.prefix(1) == "S" && $0.text.prefix(3) != "S0|"}
      case (.reply, _):      state.filteredMessages = state.messages.filter { $0.text.prefix(1) == "R" }
      }
      return .none

   case .checkForDefault:
      // is there a saved default?
      if let saved = state.defaultConnection {
        // YES, find a matching discovered packet
        for packet in state.discovery!.packets where saved.source == packet.source.rawValue && saved.serial == packet.serial {
          // found one
          return Effect(value: .pickerAction(.openSelection(PickerSelection(packet, saved.station, nil))))
        }
      }
      // NO default or failed to find a match, open the Picker
      state.pickerState = PickerState(connectionType: state.isGui ? .gui : .nonGui)
      return .none
      
    case .logAlert(let logEntry):
      // a Warning or Error has been logged. alert the user
      state.alert = .init(title: TextState(
                              """
                              An ERROR or WARNING was logged:
                              
                              \(logEntry.msg)
                              \(logEntry.level == .warning ? "Warning" : "Error")
                              """
                              )
      )
      return .none

    case .tcpAction(let message):
      // process TCP messages (both sent and received)
      // ignore "ping" messages unless showPings is true
      if message.direction == .sent && message.text.contains("ping") && state.showPings == false { return .none }
      // add the message to the collection
      state.messages.append(message)
//      state.update.toggle()
      // trigger a re-filter
      return Effect(value: .filterMessages(state.messagesFilterBy, state.messagesFilterByText))

    case .cancelEffects:
      return .cancel(ids: LogAlertId(), SentCommandId(), ReceivedCommandId())
    }
  }
)
//  .debug("APIVIEWER ")
