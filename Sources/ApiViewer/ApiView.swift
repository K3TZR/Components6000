//
//  ApiView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 12/1/21.
//

import SwiftUI
import ComposableArchitecture

import Login
import Picker
import Shared

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct ApiView: View {
  let store: Store<ApiState, ApiAction>
  
  public init(store: Store<ApiState, ApiAction>) {
    self.store = store
  }
  
  public var body: some View {
        
    WithViewStore(self.store) { viewStore in
      VStack(alignment: .leading) {
        TopButtonsView(store: store)
        SendView(store: store)
        //        FiltersView(tester: tester)
        
        Divider().background(Color(.red))
        
        VSplitView {
          ObjectsView(store: store)
          Divider().background(Color(.green))
          MessagesView(store: store)
        }
        Spacer()
        Divider().background(Color(.red))
        BottomButtonsView(store: store)
      }
      .toolbar {
        Button("Log View") { viewStore.send(.logViewButton) }
      }
      .sheet(
        isPresented: viewStore.binding(
          get: { $0.pickerState != nil },
          send: ApiAction.sheetClosed),
        content: {
          IfLetStore(
            store.scope(state: \.pickerState,
                        action: ApiAction.pickerAction
                       ),
            then: PickerView.init(store:)
          )
        }
      )
      .sheet(
        isPresented: viewStore.binding(
          get: { $0.loginState != nil },
          send: ApiAction.loginClosed),
        content: {
          IfLetStore(
            store.scope(state: \.loginState,
                        action: ApiAction.loginAction
                       ),
            then: LoginView.init(store:)
          )
        }
      )
    }
  }
}

struct TopButtonsView: View {
  let store: Store<ApiState, ApiAction>
  
  @State var smartlinkIsLoggedIn = false
  @State var smartlinkIsEnabled = false
  
  var body: some View {
    
    WithViewStore(self.store) { viewStore in
      HStack(spacing: 30) {
        Button(viewStore.connectedPacket == nil ? "Start" : "Stop") {
          viewStore.send(.startStopButton)
        }
        .keyboardShortcut(viewStore.connectedPacket == nil ? .defaultAction : .cancelAction)
        
        HStack(spacing: 20) {
          Toggle("Gui", isOn: viewStore.binding(get: \.isGui, send: .isGuiButton))
          Toggle("Times", isOn: viewStore.binding(get: \.showTimes, send: .showTimesButton))
          Toggle("Pings", isOn: viewStore.binding(get: \.showPings, send: .showPingsButton))
          Toggle("Replies", isOn: viewStore.binding(get: \.showReplies, send: .showRepliesButton))
          Toggle("WanLogin", isOn: viewStore.binding(get: \.wanLogin, send: .wanLoginButton)).disabled(viewStore.connectionMode == .local)
        }
        
        Spacer()
        Picker("", selection: viewStore.binding(
          get: \.connectionMode,
          send: { .modePicker($0) }
        )) {
          Text("Local").tag(ConnectionMode.local)
          Text("Smartlink").tag(ConnectionMode.smartlink)
          Text("Both").tag(ConnectionMode.both)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 200)

        Spacer()
        Button("Clear Default") { viewStore.send(.clearDefaultButton) }
      }
      .alert(
        item: viewStore.binding(
          get: { $0.alert },
          send: .alertDismissed
        ),
        content: { Alert(title: Text($0.title)) }
      )
      .onAppear(perform: {viewStore.send(.onAppear)})
    }
  }
}

public struct AlertView: Equatable, Identifiable {
  public var title: String
  public var id: String { self.title }
}

struct SendView: View {
  let store: Store<ApiState, ApiAction>
  
  @State var someText = ""
  
  var body: some View {
    
    WithViewStore(self.store) { viewStore in
      HStack(spacing: 25) {
        Group {
          Button("Send") { viewStore.send(.sendButton) }
          .keyboardShortcut(.defaultAction)
          
          HStack(spacing: 0) {
            Button("X") { viewStore.send(.commandTextfield("")) }
            .frame(width: 17, height: 17)
            .cornerRadius(20)
            .disabled(viewStore.connectedPacket == nil)
            TextField("Command to send", text: viewStore.binding(
              get: \.commandToSend,
              send: { value in .commandTextfield(value) } ))
          }
        }
        .disabled(viewStore.connectedPacket == nil)
        
        Spacer()
        Toggle("Clear on Send", isOn: viewStore.binding(get: \.clearOnSend, send: .clearOnSendButton))
      }
    }
  }
}

struct ObjectsView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      Text("----- Objects go here -----")
        .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
    }
  }
}

struct MessagesView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    
    WithViewStore(self.store) { viewStore in
      Text("----- Messages go here -----")
        .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
    }
  }
}

struct BottomButtonsView: View {
  let store: Store<ApiState, ApiAction>
  
  @State var fontSize: CGFloat = 12
  
  var body: some View {
    
    WithViewStore(self.store) { viewStore in
      HStack {
        Stepper("Font Size",
                value: viewStore.binding(
                  get: \.fontSize,
                  send: { value in .fontSizeStepper(value) }),
                in: 8...14)
        Text(String(format: "%2.0f", viewStore.fontSize)).frame(alignment: .leading)
        Spacer()
        HStack(spacing: 40) {
          Toggle("Clear on Connect", isOn: viewStore.binding(get: \.clearOnConnect, send: .clearOnConnectButton))
          Toggle("Clear on Disconnect", isOn: viewStore.binding(get: \.clearOnDisconnect, send: .clearOnDisconnectButton))
          Button("Clear Now") { viewStore.send(.clearNowButton)}
        }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct TopButtonsView_Previews: PreviewProvider {
  static var previews: some View {
    TopButtonsView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
  }
}

struct SendView_Previews: PreviewProvider {
  static var previews: some View {
    SendView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
  }
}

struct ObjectsView_Previews: PreviewProvider {
  static var previews: some View {
    ObjectsView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
  }
}

struct MessagesView_Previews: PreviewProvider {
  static var previews: some View {
    MessagesView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
  }
}

struct BottomButtonsView_Previews: PreviewProvider {
  static var previews: some View {
    BottomButtonsView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
  }
}
