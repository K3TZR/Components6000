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
import Connection
import Discovery
import TcpCommands
import UdpStreams
import Radio
import XCGWrapper
import Shared
import LogViewer

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
  // State held in User Defaults
  public var clearOnConnect: Bool { didSet { UserDefaults.standard.set(clearOnConnect, forKey: "clearOnConnect") } }
  public var clearOnDisconnect: Bool { didSet { UserDefaults.standard.set(clearOnDisconnect, forKey: "clearOnDisconnect") } }
  public var clearOnSend: Bool { didSet { UserDefaults.standard.set(clearOnSend, forKey: "clearOnSend") } }
  public var connectionMode: ConnectionMode { didSet { UserDefaults.standard.set(connectionMode.rawValue, forKey: "connectionMode") } }
  public var defaultConnection: DefaultConnection? { didSet { setDefaultConnection(defaultConnection) } }
  public var fontSize: CGFloat { didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") } }
  public var isGui: Bool { didSet { UserDefaults.standard.set(isGui, forKey: "isGui") } }
  public var wanLogin: Bool { didSet { UserDefaults.standard.set(wanLogin, forKey: "wanLogin") } }
  public var showTimes: Bool { didSet { UserDefaults.standard.set(showTimes, forKey: "showTimes") } }
  public var showPings: Bool { didSet { UserDefaults.standard.set(showPings, forKey: "showPings") } }
  public var smartlinkEmail: String { didSet { UserDefaults.standard.set(smartlinkEmail, forKey: "smartlinkEmail") } }
  public var objectsFilterBy: ObjectsFilter { didSet { UserDefaults.standard.set(objectsFilterBy.rawValue, forKey: "objectsFilterBy") } }
  public var messagesFilterBy: MessagesFilter { didSet { UserDefaults.standard.set(messagesFilterBy.rawValue, forKey: "messagesFilterBy") } }
  public var messagesFilterByText: String { didSet { UserDefaults.standard.set(messagesFilterByText, forKey: "messagesFilterByText") } }
  
  // normal state
  public var alert: AlertState<ApiAction>?
  public var appName: String
  public var domain: String
  public var clearNow = false
  public var commandToSend = ""
  public var connectionState: ConnectionState?
  public var discovery: Discovery? = nil
  public var filteredMessages = IdentifiedArrayOf<TcpMessage>()
  public var forceWanLogin = false
  public var loginState: LoginState? = nil
  public var messages = IdentifiedArrayOf<TcpMessage>()
  public var pickerState: PickerState? = nil
  public var radio: Radio?
  public var reverse = false
  public var tcp = Tcp()
  public var update = false
  public var viewType: ViewType = .api
  public var xcgWrapper: XCGWrapper?
  
  public var cancellables = Set<AnyCancellable>()
  
  public init(
    domain: String,
    appName: String,
    isGui: Bool = UserDefaults.standard.bool(forKey: "isGui"),
    radio: Radio? = nil
  )
  {
    self.appName = appName
    clearOnConnect = UserDefaults.standard.bool(forKey: "clearOnConnect")
    clearOnDisconnect = UserDefaults.standard.bool(forKey: "clearOnDisconnect")
    clearOnSend = UserDefaults.standard.bool(forKey: "clearOnSend")
    connectionMode = ConnectionMode(rawValue: UserDefaults.standard.string(forKey: "connectionMode") ?? "both") ?? .both
    defaultConnection = getDefaultConnection()
    self.domain = domain
    fontSize = UserDefaults.standard.double(forKey: "fontSize") == 0 ? 12 : UserDefaults.standard.double(forKey: "fontSize")
    self.isGui = isGui
    messagesFilterBy = MessagesFilter(rawValue: UserDefaults.standard.string(forKey: "messagesFilterBy") ?? "all") ?? .all
    messagesFilterByText = UserDefaults.standard.string(forKey: "messagesFilterByText") ?? ""
    objectsFilterBy = ObjectsFilter(rawValue: UserDefaults.standard.string(forKey: "objectsFilterBy") ?? "core") ?? .core
    self.radio = radio
    showPings = UserDefaults.standard.bool(forKey: "showPings")
    showTimes = UserDefaults.standard.bool(forKey: "showTimes")
    smartlinkEmail = UserDefaults.standard.string(forKey: "smartlinkEmail") ?? ""
    wanLogin = UserDefaults.standard.bool(forKey: "wanLogin")
  }
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
  case alertCancelled
  case connectionAction(ConnectionAction)
  case loginAction(LoginAction)
  case pickerAction(PickerAction)

  // Effects related
  case checkConnectionStatus(PickerSelection)
  case filterMessages(MessagesFilter, String)
  case findDefault
  case logAlert(LogEntry)
  case openRadio(PickerSelection, Handle?)
  case tcpAction(TcpMessage)
  case finishInitialization
}

public struct ApiEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main }
  )
  {
    self.queue = queue
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue>
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
  connectionReducer
    .optional()
    .pullback(
      state: \ApiState.connectionState,
      action: /ApiAction.connectionAction,
      environment: { _ in ConnectionEnvironment() }
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
      // MARK: - ApiView initialization
      
    case .onAppear:
      // if the first time, start Logger, Discovery and the Listeners
      if state.xcgWrapper == nil {
//        state.xcgWrapper = XCGWrapper()
//        state.discovery = Discovery.sharedInstance
//        // listen for broadcast packets
//        listenForPackets(state.discovery)
        // capture TCP messages (sent & received)
        return .merge(logAlerts(), sentMessages(state.tcp), receivedMessages(state.tcp), Effect(value: .finishInitialization))
      }
      return .none

    case .finishInitialization:
      state.xcgWrapper = XCGWrapper()
      state.discovery = Discovery.sharedInstance
      // listen for broadcast packets
      listenForPackets(state.discovery)
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - ApiView control actions
      
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
      listenForPackets(state.discovery)
      return .none
      
    case .fontSizeStepper(let size):
      state.fontSize = size
      return .none
      
    case .forceLoginButton:
      let savedMode = state.connectionMode
      // stop all listeners
      state.connectionMode = .none
      listenForPackets(state.discovery)
      // set the flag and restart listeners
      state.forceWanLogin = true
      state.connectionMode = savedMode
      listenForPackets(state.discovery)
      // reset the flag
      state.forceWanLogin = false
      return .none
      
    case .logViewButton:
      state.viewType = .log
      return .none
      
    case .messagesPicker(let filter):
      state.messagesFilterBy = filter
      return Effect(value: .filterMessages(state.messagesFilterBy, state.messagesFilterByText))

    case .messagesFilterTextField(let text):
      state.messagesFilterByText = text
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
      if state.radio == nil {
        // NOT connected, is there a default
        return Effect(value: .findDefault)
        
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
      // MARK: - Picker actions
      
    case .pickerAction(.cancelButton):
      state.pickerState = nil
      return .none
      
    case .pickerAction(.connectButton(let selection)):
      state.pickerState = nil
      // check for other Gui Clients
      return Effect(value: .checkConnectionStatus(selection))
      
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
      // MARK: - Login actions
      
    case .loginAction(.cancelButton):
      state.loginState = nil
      return .none
      
    case .loginAction(.loginButton(let credentials)):
      state.loginState = nil
      state.smartlinkEmail = credentials.email
      state.alert = startWanListener(state.discovery!, using: credentials)
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Connection actions
      
    case .connectionAction(.cancelButton):
      state.connectionState = nil
      return .none
      
    case .connectionAction(.connect(let selection, let handle)):
      state.connectionState = nil
      return Effect(value: .openRadio(selection, handle))
      
      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertCancelled:
      state.alert = nil
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - ApiEffects actions
            
    case .tcpAction(let message):
      // process received TCP messages
      if message.direction == .sent && message.text.contains("ping") && state.showPings == false { return .none }
      state.messages.append(message)
      state.update.toggle()
      return Effect(value: .filterMessages(state.messagesFilterBy, state.messagesFilterByText))
      
    case .filterMessages(let filterBy, let filterText):
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

    case .openRadio(let selection, let handle):
      // instantiate a Radio object
      state.radio = Radio(selection.packet,
                          connectionType: state.isGui ? .gui : .nonGui,
                          command: state.tcp,
                          stream: Udp(),
                          stationName: "Api6000",
                          programName: "Api6000",
                          disconnectHandle: handle,
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
      
    case .checkConnectionStatus(let selection):
      if Shared.kVersionSupported < Version(selection.packet.version)  {
        // NO, return an Alert
        state.alert = .init(title: TextState(
                                """
                                Radio may be incompatible:
                                
                                Radio version is \(Version(selection.packet.version).string)
                                App supports <= \(kVersionSupported.string)
                                """
                                )
        )
      }
      if state.isGui && selection.packet.guiClients.count > 0 {
        // YES, may need a disconnect, let the user choose
        state.connectionState = ConnectionState(pickerSelection: selection)
      } else {
        // NO, open the radio
        return Effect(value: .openRadio(selection, nil))
      }
      return .none
      
    case .findDefault:
      // is there a saved default with a matching broadcast packet?
      if let saved = state.defaultConnection {
        // YES, find a matching discovered packet
        for packet in state.discovery!.packets where saved.source == packet.source.rawValue && saved.serial == packet.serial {
          return Effect(value: .checkConnectionStatus(PickerSelection(packet, saved.station)))
        }
      }
      // NO, open the Picker
      state.pickerState = PickerState(connectionType: state.isGui ? .gui : .nonGui)
      return .none
      
    case .logAlert(let logEntry):
      state.alert = .init(title: TextState(
                              """
                              An ERROR or WARNING was logged:
                              
                              \(logEntry.msg)
                              \(logEntry.level == .warning ? "Warning" : "Error")
                              """
                              )
      )
      return .none
    }
  }
)
//  .debug("API ")
