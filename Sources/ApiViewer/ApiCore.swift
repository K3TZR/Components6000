//
//  ApiCore.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 11/24/21.
//

import ComposableArchitecture
import Dispatch
import SwiftUI

import Login
import Picker
import Discovery
import Commands
import Shared

struct CommandSubscriptionId: Hashable {}

public struct DefaultConnection: Codable, Equatable {

  public static func == (lhs: DefaultConnection, rhs: DefaultConnection) -> Bool {
    guard lhs.source == rhs.source else { return false }
    guard lhs.publicIp == rhs.publicIp else { return false }
    return true
  }

  var source: String
  var publicIp: String

  enum CodingKeys: String, CodingKey {
    case source
    case publicIp
  }
}

public enum ConnectionMode: String {
  case local
  case smartlink
  case both
}

public struct CommandMessage: Equatable, Identifiable {
  public var id = UUID()
  var text: Substring
  var color: Color
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
  public var showReplies: Bool { didSet { UserDefaults.standard.set(showReplies, forKey: "showReplies") } }
  public var smartlinkEmail: String { didSet { UserDefaults.standard.set(smartlinkEmail, forKey: "smartlinkEmail") } }

  // normal state
  public var clearNow = false
  public var command = Command()
  public var commandToSend = ""
  public var connectedPacket: Packet? = nil
  public var discovery: Discovery? = nil
  public var alert: AlertView?
  public var loginState: LoginState? = nil
  public var commandMessages = IdentifiedArrayOf<CommandMessage>()
  public var pickerState: PickerState? = nil
  public var update = false
    
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
    showReplies = UserDefaults.standard.bool(forKey: "showReplies")
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
      if let discovery = state.discovery {
        for packet in discovery.packets {
          discovery.packets[id: packet.id]?.isDefault = false
        }
      }
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
      listenForPackets(&state)
      return listenForCommands(state.command)
      
    case .sendButton:
      _ = state.command.send(state.commandToSend)
      return .none

    case .sheetClosed:
      state.pickerState = nil
      return .none
      
    case .startStopButton:
      if state.connectedPacket == nil {
        // NOT connected, attempt a connection
        if let packet = identifyDefault(state.defaultConnection, state.discovery!) {
          // using the default
          if state.command.connect(packet) {
            // default connected
            state.connectedPacket = packet
            if state.clearOnConnect { state.commandMessages.removeAll() }
          } else {
            // default failed to open
            state.connectedPacket = nil
            state.alert = AlertView(title: "Failed to connect to \(packet.nickname) (default)")
            // open the Picker
            state.pickerState = PickerState(pickType: state.isGui ? .radio : .station)
          }
        } else {
          // no default, open the Picker
          state.pickerState = PickerState(pickType: state.isGui ? .radio : .station)
        }

      } else {
        // CONNECTED, disconnect
        state.command.disconnect()
        state.connectedPacket = nil
        if state.clearOnDisconnect { state.commandMessages.removeAll() }
      }
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Picker actions

    case .pickerAction(.cancelButton):
      state.pickerState = nil
      if state.clearOnDisconnect { state.commandMessages.removeAll() }
      return .none
      
    case let .pickerAction(.connectButton(packet)):
      state.pickerState = nil
      if state.command.connect(packet!) {
        state.connectedPacket = packet
        if state.clearOnConnect { state.commandMessages.removeAll() }
      } else {
        state.connectedPacket = nil
        state.alert = AlertView(title: "Failed to connect to \(packet!.nickname)")
      }
      return .none
      
    case let .pickerAction(.connectResultReceived(index)):
      print("-----> ApiCore: \(action) NOT IMPLEMENTED")
      return .none
      
    case let .pickerAction(.testButton(packet)):
      print("-----> ApiCore: Test, packet = \(packet!.nickname)")
      return .none
      
    case let .pickerAction(.defaultChanged(packet)):
      if packet.isDefault {
        // save the dafault
        state.defaultConnection = DefaultConnection(source: packet.source.rawValue, publicIp: packet.publicIp)
        // close the picker and connect
        return Effect(value: .pickerAction(.connectButton(packet)))

      } else {
        state.defaultConnection = nil
        return .none
      }

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
      listenForWanPackets(&state, loginResult: result)
      return .none
      
    case .loginClosed:
      state.loginState = nil
      print("-----> ApiViewer: Login closed")
      return .none
      
      // ----------------------------------------------------------------------------
      // MARK: - Alert actions
      
    case .alertDismissed:
      state.alert = nil
      return .none

      // ----------------------------------------------------------------------------
      // MARK: - Command actions

    case let .commandAction(message):

      print("-----> commandAction received")

      state.commandMessages.append(message)
      state.update.toggle()
      return .none
    }
  }
)
//  .debug("API ")

private func listenForPackets(_ state: inout ApiState) {
  if state.discovery == nil { state.discovery = Discovery.sharedInstance }
  if state.connectionMode == .local || state.connectionMode == .both {
    do {
      try state.discovery?.startLanListener()
      
    } catch LanListenerError.kSocketError {
      state.alert = AlertView(title: "Discovery: Lan Listener, Failed to open a socket")
    } catch LanListenerError.kReceivingError {
      state.alert = AlertView(title: "Discovery: Lan Listener, Failed to start receiving")
    } catch {
      state.alert = AlertView(title: "Discovery: Lan Listener, unknown error")
    }
  }
  if state.connectionMode == .smartlink || state.connectionMode == .both {
    do {
      try state.discovery?.startWanListener(smartlinkEmail: state.smartlinkEmail, force: state.wanLogin)
      
    } catch WanListenerError.kFailedToObtainIdToken {
      state.loginState = LoginState(email: state.smartlinkEmail)
      
    } catch WanListenerError.kFailedToConnect {
      state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Connect")
    } catch {
      state.alert = AlertView(title: "Discovery: Wan Listener, unknown error")
    }
  }
}

private func listenForWanPackets(_ state: inout ApiState, loginResult: LoginResult) {
  state.smartlinkEmail = loginResult.email
  state.loginState = nil
  do {
    try state.discovery?.startWanListener(using: loginResult)
    
  } catch WanListenerError.kFailedToObtainIdToken {
    state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Obtain IdToken")
  } catch WanListenerError.kFailedToConnect {
    state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Connect")
  } catch {
    state.alert = AlertView(title: "Discovery: Wan Listener, unknown error")
  }
}

private func identifyDefault(_ conn: DefaultConnection?, _ discovery: Discovery) -> Packet? {
  guard conn != nil else { return nil }
  for packet in discovery.packets where conn!.source == packet.source.rawValue && conn!.publicIp == packet.publicIp {
    return packet
  }
  return nil
}

private func getDefaultConnection() -> DefaultConnection? {
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

private func setDefaultConnection(_ conn: DefaultConnection?) {
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
