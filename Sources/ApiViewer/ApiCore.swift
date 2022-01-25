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
  case none
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
  public var connectedPacket: PickerSelection? = nil
  public var discovery: Discovery? = nil
  public var alert: AlertView?
  public var loginState: LoginState? = nil
  public var commandMessages = IdentifiedArrayOf<CommandMessage>()
  public var filteredCommandMessages = IdentifiedArrayOf<CommandMessage>()
  public var pickerState: PickerState? = nil
  public var update = false
  public var connectionState: ConnectionState?
  public var viewType: ViewType = .api
  public var xcgWrapper: XCGWrapper?
  
  public init(domain: String, appName: String, radio: Radio? = nil) {
    self.appName = appName
    clearOnConnect = UserDefaults.standard.bool(forKey: "clearOnConnect")
    clearOnDisconnect = UserDefaults.standard.bool(forKey: "clearOnDisconnect")
    clearOnSend = UserDefaults.standard.bool(forKey: "clearOnSend")
    connectionMode = ConnectionMode(rawValue: UserDefaults.standard.string(forKey: "connectionMode") ?? "both") ?? .both
    defaultConnection = getDefaultConnection()
    self.domain = domain
    fontSize = UserDefaults.standard.double(forKey: "fontSize") == 0 ? 12 : UserDefaults.standard.double(forKey: "fontSize")
    isGui = UserDefaults.standard.bool(forKey: "isGui")
    messagesFilterBy = MessagesFilter(rawValue: UserDefaults.standard.string(forKey: "messagesFilterBy") ?? "none") ?? .none
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
  case alertDismissed
  case commandAction(CommandMessage)
  case loginAction(LoginAction)
  case loginClosed
  case onAppear
  case pickerAction(PickerAction)
  case sheetClosed
  //  case openRadio(PickerSelection)
  case connectionAction(ConnectionAction)
  case connectionClosed
  
  // UI controls
  case button(WritableKeyPath<ApiState, Bool>)
  case clearDefaultButton
  case clearNowButton
  case commandToSend(String)
  case fontSizeStepper(CGFloat)
  case logViewButton
  case apiViewButton
  case modePicker(ConnectionMode)
  case sendButton
  case startStopButton
  case objectsFilterBy(ObjectsFilter)
  case messagesFilterBy(MessagesFilter)
  case messagesFilterByText(String)
  
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
      if state.isGui && selection.packet.guiClients.count > 0 {
        // check for other stations, may need a disconnect
        state.connectionState = ConnectionState(pickerSelection: selection)
      } else {
        // simple open, no pending disconnect
        openRadio(selection, nil)
      }
    }
    
    func openRadio(_ selection: PickerSelection, _ disconnectHandle: Handle?) {
      state.radio = Radio(selection.packet,
                          connectionType: state.isGui ? .gui : .nonGui,
                          command: state.command,
                          stream: UdpStream(),
                          stationName: "Api6000",
                          programName: "Api6000",
                          disconnectHandle: disconnectHandle,
                          testerModeEnabled: true)
      if state.radio!.connect(selection.packet) {
//        state.connectedPacket = selection
        state.alert = isVersionCompatible(Version(selection.packet.version))
        if state.clearOnConnect { state.commandMessages.removeAll() }
      } else {
        state.alert = AlertView(title: "Failed to connect to Radio \(selection.packet.nickname)")
      }
    }
    
    func isVersionCompatible(_ radioVersion: Version) -> AlertView? {
      if Shared.kVersionSupported >= radioVersion  {
        return nil
      } else {
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
      // MARK: - UI actions
      
    case .apiViewButton:
      state.viewType = .api
      return .none
      
    case let .button(keyPath):
      state[keyPath: keyPath].toggle()
      if keyPath == \.wanLogin { state.alert = AlertView(title: "Takes effect when App restarted") }
      return .none
      
    case .clearDefaultButton:
      state.defaultConnection = nil
      //      if let discovery = state.discovery {
      //        for packet in discovery.packets {
      //          discovery.packets[id: packet.id]?.isDefault = false
      //        }
      //      }
      return .none
      
    case .clearNowButton:
      state.commandMessages.removeAll()
      return .none
      
    case let .commandToSend(text):
      state.commandToSend = text
      return .none
      
    case let .fontSizeStepper(size):
      state.fontSize = size
      return .none
      
    case .logViewButton:
      state.viewType = .log
      return .none
      
    case let .messagesFilterBy(choice):
      state.messagesFilterBy = choice
      return.none
      
    case let .messagesFilterByText(text):
      state.messagesFilterByText = text
      return.none
      
    case let .modePicker(mode):
      state.connectionMode = mode
      return .none
      
    case let .objectsFilterBy(filterBy):
      return.none
      
    case .onAppear:
      if state.xcgWrapper == nil { state.xcgWrapper = XCGWrapper() }
      if state.discovery == nil {
        state.discovery = Discovery.sharedInstance
        if state.connectionMode == .local || state.connectionMode == .both {
          state.alert = listenForLocalPackets(state)
        }
        if state.connectionMode == .smartlink || state.connectionMode == .both {
          let alert = listenForWanPackets(state.discovery!, using: state.smartlinkEmail, forceLogin: state.wanLogin)
          if alert != nil {
            state.alert = alert
            state.loginState = LoginState(email: state.smartlinkEmail)
          }
        }
        return messagesEffects(state.command)
        
      } else {
        return .none
      }
      
    case .sendButton:
      _ = state.command.send(state.commandToSend)
      return .none
      
    case .sheetClosed:
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
//        state.connectedPacket = nil
        state.radio = nil
        if state.clearOnDisconnect { state.commandMessages.removeAll() }
        return .none
      }
      
      // ----------------------------------------------------------------------------
      // MARK: - Picker actions
      
    case .pickerAction(.cancelButton):
      state.pickerState = nil
      if state.clearOnDisconnect { state.commandMessages.removeAll() }
      return .none
      
      // TODO: take into account the clientIndex and isGui
    case let .pickerAction(.connectButton(selection)):
      state.pickerState = nil
      checkConnectionStatus(selection)
      return .none
      
    case let .pickerAction(.connectResultReceived(index)):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case let .pickerAction(.testButton(selection)):
      print("-----> ApiCore: Test for \(selection.packet.source.rawValue), \(selection.packet.serial), \(selection.station ?? "")")
      return .none
      
    case let .pickerAction(.defaultButton(selection)):
      if state.defaultConnection == nil {
        state.defaultConnection = DefaultConnection(selection)
      } else {
        state.defaultConnection = nil
      }
      return .none
      
    case .pickerAction(_):
      // IGNORE ALL OTHERS
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Login actions
      
    case .loginAction(.cancelButton):
      print("-----> Login: Cancel button")
      state.loginState = nil
      return .none
      
    case let .loginAction(.loginButton(credentials)):
      state.loginState = nil
      state.smartlinkEmail = credentials.email
      state.alert = listenForWanPackets(state.discovery!, using: credentials)
      return .none
      
    case .loginClosed:
      state.loginState = nil
      print("-----> ApiViewer: Login closed")
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Connection actions
      
    case .connectionAction(.cancelButton):
      print("API -----> cancelButton")
      state.connectionState = nil
      return .none
      
    case let .connectionAction(.connect(selection, disconnectHandle)):
      state.connectionState = nil
      openRadio(selection, disconnectHandle)
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertDismissed:
      state.alert = nil
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Command actions
      
    case let .commandAction(message):
      if message.direction == .sent && message.text.contains("ping") && state.showPings == false { return .none }
      state.commandMessages.append(message)
      state.update.toggle()
      return .none
      
    case .connectionClosed:
      state.connectionState = nil
      return .none
    }
  }
)
//  .debug("API ")
