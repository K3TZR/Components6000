//
//  ApiCore.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 11/24/21.
//

import ComposableArchitecture
import Dispatch

import Login
import Picker
import Connection
import Discovery
import TcpCommands
import UdpStreams
import Radio
import XCGWrapper
import Shared
import SwiftUI

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
  public var appName: String
  public var domain: String
  public var radio: Radio?
  public var clearNow = false
  public var command = TcpCommand()
  public var commandToSend = ""
  public var discovery: Discovery? = nil
  public var alert: AlertView?
  public var loginState: LoginState? = nil
  public var messages = IdentifiedArrayOf<Message>()
  public var filteredMessages = IdentifiedArrayOf<Message>()
  public var pickerState: PickerState? = nil
  public var update = false
  public var connectionState: ConnectionState?
  public var viewType: ViewType = .api
  public var xcgWrapper: XCGWrapper?
  
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
  case toggleButton(WritableKeyPath<ApiState, Bool>)
  case clearDefaultButton
  case clearNowButton
  case commandTextField(String)
  case fontSizeStepper(CGFloat)
  case logViewButton
  case apiViewButton
  case connectionModePicker(ConnectionMode)
  case sendButton
  case startStopButton
  case objectsPicker(ObjectsFilter)
  case messagesPicker(MessagesFilter)
  case messagesFilterTextField(String)
  
  // sheet/alert related
  case alertClosed
  case connectionAction(ConnectionAction)
  case connectionSheetClosed
  case loginAction(LoginAction)
  case loginSheetClosed
  case pickerAction(PickerAction)
  case pickerSheetClosed

  // Effects related
  case commandAction(Message)
  case filterMessages(MessagesFilter, String)
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
    
    func checkConnectionStatus(_ selection: PickerSelection) {
      // are there other Gui Clients?
      if state.isGui && selection.packet.guiClients.count > 0 {
        // YES, may need a disconnect
        state.connectionState = ConnectionState(pickerSelection: selection)
      } else {
        // NO, no pending disconnect
        openRadio(selection, nil)
      }
    }
    
    func openRadio(_ selection: PickerSelection, _ disconnectHandle: Handle?) {
      // instantiate a Radio object
      state.radio = Radio(selection.packet,
                          connectionType: state.isGui ? .gui : .nonGui,
                          command: state.command,
                          stream: UdpStream(),
                          stationName: "Api6000",
                          programName: "Api6000",
                          disconnectHandle: disconnectHandle,
                          testerModeEnabled: true)
      // try to connect
      if state.radio!.connect(selection.packet) {
        // check the radio's version
        state.alert = isVersionCompatible(Version(selection.packet.version))
        if state.clearOnConnect {
          state.messages.removeAll()
          state.filteredMessages.removeAll()
        }
      } else {
        state.alert = AlertView(title: "Failed to connect to Radio \(selection.packet.nickname)")
      }
    }
    
    func isVersionCompatible(_ radioVersion: Version) -> AlertView? {
      // compatible version?
      if Shared.kVersionSupported >= radioVersion  {
        // YES
        return nil
      } else {
        // NO, return an Alert
        return AlertView(title:
                                """
                                Radio may be incompatible:
                                
                                Radio version is \(radioVersion.string)
                                App supports <= \(kVersionSupported.string)
                                """)
      }
    }
    
    switch action {      
      
      // ----------------------------------------------------------------------------
      // MARK: - ApiView initialization
      
    case .onAppear:
      // if the first time, start the logger and Discovery
      if state.xcgWrapper == nil { state.xcgWrapper = XCGWrapper() }
      if state.discovery == nil {
        state.discovery = Discovery.sharedInstance
        if state.connectionMode == .local || state.connectionMode == .both {
          // try to start listening for Lan packets
          state.alert = listenForLocalPackets(state)
        }
        if state.connectionMode == .smartlink || state.connectionMode == .both {
          // try to start listening for smartlink packets
          let alert = listenForWanPackets(state.discovery!, using: state.smartlinkEmail, forceLogin: state.wanLogin)
          if alert != nil {
            // something went wrong, show the alert
            state.alert = alert
            // show the Login sheet
            state.loginState = LoginState(email: state.smartlinkEmail)
          }
        }
        // start listening for messages (TCP)
        return messagesEffects(state.command)
        
      } else {
        return .none
      }
      
      // ----------------------------------------------------------------------------
      // MARK: - ApiView control actions
      
    case .apiViewButton:
      state.viewType = .api
      return .none
      
    case .toggleButton(let keyPath):
      // handles all buttons with a Bool state
      state[keyPath: keyPath].toggle()
      if keyPath == \.wanLogin { state.alert = AlertView(title: "Takes effect when App restarted") }
      return .none
      
    case .clearDefaultButton:
      state.defaultConnection = nil
      return .none
      
    case .clearNowButton:
      state.messages.removeAll()
      return .none
      
    case .commandTextField(let text):
      state.commandToSend = text
      return .none
      
    case .fontSizeStepper(let size):
      state.fontSize = size
      return .none
      
    case .logViewButton:
      state.viewType = .log
      return .none
      
    case .messagesPicker(let filter):
      state.messagesFilterBy = filter
      return Effect(value: .filterMessages(filter, state.messagesFilterByText))

    case .messagesFilterTextField(let text):
      state.messagesFilterByText = text
      return Effect(value: .filterMessages(state.messagesFilterBy, text))
      
    case .connectionModePicker(let mode):
      state.connectionMode = mode
      return .none
      
    case .objectsPicker(let filterBy):
      state.objectsFilterBy = filterBy
      return.none
      
    case .sendButton:
      _ = state.command.send(state.commandToSend)
      return .none
      
    case .pickerSheetClosed:
      state.pickerState = nil
      return .none
      
    case .startStopButton:
      if state.radio == nil {
        // NOT connected, is there a default?
        if let def = state.defaultConnection {
          // YES, find a matching discovered packet
          for packet in state.discovery!.packets where def.source == packet.source.rawValue && def.serial == packet.serial {
            checkConnectionStatus(PickerSelection(packet, def.station))
            return .none
          }
        }
        // otherwise, open the Picker
        state.pickerState = PickerState(connectionType: state.isGui ? .gui : .nonGui)
        return .none
        
      } else {
        // CONNECTED, disconnect
        state.radio!.disconnect()
        state.radio = nil
        if state.clearOnDisconnect {
          state.messages.removeAll()
          state.filteredMessages.removeAll()
        }
        return .none
      }
      
      // ----------------------------------------------------------------------------
      // MARK: - Picker actions
      
    case .pickerAction(.cancelButton):
      state.pickerState = nil
      return .none
      
    case .pickerAction(.connectButton(let selection)):
      state.pickerState = nil
      // check for other Gui CLients
      checkConnectionStatus(selection)
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
      // MARK: - Login actions
      
    case .loginAction(.cancelButton):
      state.loginState = nil
      return .none
      
    case .loginAction(.loginButton(let credentials)):
      state.loginState = nil
      state.smartlinkEmail = credentials.email
      state.alert = listenForWanPackets(state.discovery!, using: credentials)
      return .none
      
    case .loginSheetClosed:
      state.loginState = nil
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Connection actions
      
    case .connectionAction(.cancelButton):
      state.connectionState = nil
      return .none
      
    case .connectionAction(.connect(let selection, let disconnectHandle)):
      state.connectionState = nil
      // Open the selected packet (may require a disconnection prior to opening)
      openRadio(selection, disconnectHandle)
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertClosed:
      state.alert = nil
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - ApiEffects actions
      
    case let .commandAction(message):
      // process received TCP messages
      if message.direction == .sent && message.text.contains("ping") && state.showPings == false { return .none }
      state.messages.append(message)
      state.update.toggle()
      return Effect(value: .filterMessages(state.messagesFilterBy, state.messagesFilterByText))

    case .connectionSheetClosed:
      state.connectionState = nil
      return .none
      
    case .filterMessages(let filterBy, let filterText):
      switch (filterBy, filterText) {

      case (.all, _):       state.filteredMessages = state.messages
      case (.prefix, ""):    state.filteredMessages = state.messages
      case (.prefix, _):     state.filteredMessages = state.messages.filter { $0.text.localizedCaseInsensitiveContains("|" + filterText) }
//      case (.includes, ""):  state.filteredCommandMessages = [Message]()
      case (.includes, _):   state.filteredMessages = state.messages.filter { $0.text.localizedCaseInsensitiveContains(filterText) }
      case (.excludes, ""):  state.filteredMessages = state.messages
      case (.excludes, _):   state.filteredMessages = state.messages.filter { !$0.text.localizedCaseInsensitiveContains(filterText) }
      case (.command, _):    state.filteredMessages = state.messages.filter { $0.text.prefix(1) == "C" }
      case (.S0, _):         state.filteredMessages = state.messages.filter { $0.text.prefix(3) == "S0|" }
      case (.status, _):     state.filteredMessages = state.messages.filter { $0.text.prefix(1) == "S" && $0.text.prefix(3) != "S0|"}
      case (.reply, _):      state.filteredMessages = state.messages.filter { $0.text.prefix(1) == "R" }
      }

      state.update.toggle()
      return .none
    }
  }
)
//  .debug("API ")
