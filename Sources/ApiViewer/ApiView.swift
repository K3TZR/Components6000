//
//  ApiView.swift
//  TestDiscoveryPackage/ApiViewer
//
//  Created by Douglas Adams on 12/1/21.
//

import SwiftUI
import ComposableArchitecture

import Picker
import Shared

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
        Button("Log View") { viewStore.send(.buttonTapped(.logView)) }
      }
      .sheet(
        isPresented: viewStore.binding(
          get: { $0.pickerState != nil },
          send: ApiAction.sheetClosed),
        content: {
          IfLetStore(
            store.scope(state: \.pickerState, action: ApiAction.pickerAction),
            then: PickerView.init(store:)
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
          viewStore.send(.buttonTapped(.startStop))
        }
        .keyboardShortcut(viewStore.connectedPacket == nil ? .defaultAction : .cancelAction)
        .help("Using the Default connection type")
        
        HStack(spacing: 20) {
          Toggle("Gui", isOn: viewStore.binding(get: \.isGui, send: .buttonTapped(.isGui)))
          Toggle("Times", isOn: viewStore.binding(get: \.showTimes, send: .buttonTapped(.showTimes)))
          Toggle("Pings", isOn: viewStore.binding(get: \.showPings, send: .buttonTapped(.showPings)))
          Toggle("Replies", isOn: viewStore.binding(get: \.showReplies, send: .buttonTapped(.showReplies)))
          Toggle("Buttons", isOn: viewStore.binding(get: \.showButtons, send: .buttonTapped(.showButtons)))
        }
        
        Spacer()
        HStack(spacing: 10) {
          Text("SmartLink")
          Button(smartlinkIsLoggedIn ? "Logout" : "Login") { viewStore.send(.buttonTapped(.smartlinkLogin)) }
          
          Button("Status") { viewStore.send(.buttonTapped(.status)) }
        }.disabled(viewStore.connectedPacket != nil)
        
        Spacer()
        Button("Clear Default") { viewStore.send(.buttonTapped(.clearDefault)) }
      }
      .onAppear(perform: { viewStore.send(.onAppear) })
      .alert(
        item: viewStore.binding(
          get: { $0.discoveryAlert },
          send: .discoveryAlertDismissed
        ),
        content: { Alert(title: Text($0.title)) }
      )

    }
  }
}

public struct DiscoveryAlert: Equatable, Identifiable {
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
          Button("Send") { viewStore.send(.buttonTapped(.send)) }
          .keyboardShortcut(.defaultAction)
          
          HStack(spacing: 0) {
            Button("X") { viewStore.send(.commandToSendChanged("")) }
            .frame(width: 17, height: 17)
            .cornerRadius(20)
            .disabled(viewStore.connectedPacket == nil)
            TextField("Command to send", text: viewStore.binding(
              get: \.commandToSend,
              send: { value in .commandToSendChanged(value) } ))
          }
        }
        .disabled(viewStore.connectedPacket == nil)
        
        Spacer()
        Toggle("Clear on Send", isOn: viewStore.binding(get: \.clearOnSend, send: .buttonTapped(.clearOnSend)))
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
        .frame(minWidth: 950, minHeight: 100, idealHeight: 200, maxHeight: 300, alignment: .leading)
    }
  }
}

struct MessagesView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    
    WithViewStore(self.store) { viewStore in
      Text("----- Messages go here -----")
        .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
        .frame(minWidth: 950, minHeight: 100, idealHeight: 200, maxHeight: 300, alignment: .leading)
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
                  send: { value in .fontSizeChanged(value) }),
                in: 8...14)
        Text(String(format: "%2.0f", viewStore.fontSize)).frame(alignment: .leading)
        Spacer()
        HStack(spacing: 40) {
          Toggle("Clear on Connect", isOn: viewStore.binding(get: \.clearOnConnect, send: .buttonTapped(.clearOnConnect)))
          Toggle("Clear on Disconnect", isOn: viewStore.binding(get: \.clearOnDisconnect, send: .buttonTapped(.clearOnDisconnect)))
          Button("Clear Now") { viewStore.send(.buttonTapped(.clearNow))}
        }
      }
    }
  }
}

struct TopButtonsView_Previews: PreviewProvider {
  static var previews: some View {
    TopButtonsView(
      store: Store(
        initialState: ApiState(fontSize: 12, smartlinkEmail: "douglas.adams@me.com"),
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
        initialState: ApiState(fontSize: 12, smartlinkEmail: "douglas.adams@me.com"),
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
        initialState: ApiState(fontSize: 12, smartlinkEmail: "douglas.adams@me.com"),
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
        initialState: ApiState(fontSize: 12, smartlinkEmail: "douglas.adams@me.com"),
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
        initialState: ApiState(fontSize: 12, smartlinkEmail: "douglas.adams@me.com"),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
  }
}
