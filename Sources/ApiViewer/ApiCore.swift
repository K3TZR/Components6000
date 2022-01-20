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
import Shared

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

  // normal state
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

  public init() {
    clearOnConnect = UserDefaults.standard.bool(forKey: "clearOnConnect")
    clearOnDisconnect = UserDefaults.standard.bool(forKey: "clearOnDisconnect")
    clearOnSend = UserDefaults.standard.bool(forKey: "clearOnSend")
    connectionMode = ConnectionMode(rawValue: UserDefaults.standard.string(forKey: "connectionMode") ?? "both") ?? .both
    defaultConnection = getDefaultConnection()
    fontSize = UserDefaults.standard.double(forKey: "fontSize") == 0 ? 12 : UserDefaults.standard.double(forKey: "fontSize")
    isGui = UserDefaults.standard.bool(forKey: "isGui")
    wanLogin = UserDefaults.standard.bool(forKey: "wanLogin")
    showTimes = UserDefaults.standard.bool(forKey: "showTimes")
    showPings = UserDefaults.standard.bool(forKey: "showPings")
    smartlinkEmail = UserDefaults.standard.string(forKey: "smartlinkEmail") ?? ""
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
  case openRadio(PickerSelection)
  case connectionAction(ConnectionAction)
  case connectionClosed

  // UI controls
  case button(WritableKeyPath<ApiState, Bool>)
  case clearDefaultButton
  case clearNowButton
  case commandTextfield(String)
  case fontSizeStepper(CGFloat)
  case logViewButton
  case modePicker(ConnectionMode)
  case sendButton
  case startStopButton

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
    switch action {
      
      // ----------------------------------------------------------------------------
      // MARK: - UI actions

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

    case let .commandTextfield(value):
      state.commandToSend = value
      return .none
      
    case let .fontSizeStepper(size):
      state.fontSize = size
      return .none
      
    case .logViewButton:
      // handled by Root
      return .none

    case let .modePicker(mode):
      state.connectionMode = mode
      return .none

    case .onAppear:
      if state.discovery == nil { state.discovery = Discovery.sharedInstance }
      if state.connectionMode == .local || state.connectionMode == .both {
        state.alert = listenForLocalPackets(state)
      }
      if state.connectionMode == .smartlink || state.connectionMode == .both {
        let alert = listenForWanPackets(state)
        if alert != nil {
          state.alert = alert
          state.loginState = LoginState(email: state.smartlinkEmail)
        }
      }
      return listenForCommands(state.command)
      
    case .sendButton:
      _ = state.command.send(state.commandToSend)
      return .none

    case .sheetClosed:
      state.pickerState = nil
      return .none
      
    case .startStopButton:
      if state.connectedPacket == nil {
        // NOT connected, is there a default?
        if let def = state.defaultConnection {
          // YES, find a matching discovered packet
          for packet in state.discovery!.packets where def.source == packet.source.rawValue && def.serial == packet.serial {
            return Effect( value: .openRadio(PickerSelection(packet, def.station)) )
          }
        }
        // otherwise, open the Picker
        state.pickerState = PickerState(pickType: state.isGui ? .radio : .station)
        return .none

      } else {
        // CONNECTED, disconnect
        state.command.disconnect()
        state.connectedPacket = nil
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
      if selection.packet.guiClients.count > 0 {
        state.connectionState = ConnectionState(pickerSelection: selection)
        return .none
      } else {
        return Effect( value: .openRadio(selection) )
      }

    case .openRadio(let selection):
      state.radio = Radio(selection.packet, connectionType: state.isGui ? .gui : .nonGui, command: state.command, stream: UdpStream())
      if state.radio!.connect(selection.packet) {
        state.connectedPacket = selection
        if state.clearOnConnect { state.commandMessages.removeAll() }
      } else {
        state.alert = AlertView(title: "Failed to connect to Radio \(selection.packet.nickname)")
      }
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
      
    case let .loginAction(.loginButton(result)):
      state.loginState = nil
      state.smartlinkEmail = result.email
      state.alert = listenForWanPackets(state, using: result)
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

    case let .connectionAction(.simpleConnect(selection)):
      print("API -----> simpleConnection to \(selection.packet.nickname)")
      state.connectionState = nil
      return Effect( value: .openRadio(selection) )

    case let .connectionAction(.disconnectThenConnect(selection, index)):
      print("API -----> DisconnectThenConnect, disconnect \(selection.packet.guiClients[index].station), connect \(selection.packet.nickname), \(selection.station ?? "none")" )
      state.connectionState = nil
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertDismissed:
      state.alert = nil
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Command actions

    case let .commandAction(message):
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
