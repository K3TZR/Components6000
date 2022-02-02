//
//  ApiView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 12/1/21.
//

import SwiftUI
import ComposableArchitecture

import Login
import Connection
import Picker
import LogViewer
import Shared

// ----------------------------------------------------------------------------
// MARK: - View

public struct ApiView: View {
  let store: Store<ApiState, ApiAction>
  
  public init(store: Store<ApiState, ApiAction>) {
    self.store = store
  }
  
  public var body: some View {
    
    WithViewStore(self.store) { viewStore in
      
      if viewStore.viewType == .api {
        VStack(alignment: .leading) {
          TopButtonsView(store: store)
          SendView(store: store)
          FiltersView(store: store)
          
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
        // initialize on first appearance
        .onAppear() { viewStore.send(.onAppear) }
        
        // alert dialogs
        .alert(
          self.store.scope(state: \.alert),
          dismiss: .alertCancelled
        )
        
        // Picker sheet
        .sheet(
          isPresented: viewStore.binding(
            get: { $0.pickerState != nil },
            send: ApiAction.pickerAction(.cancelButton)),
          content: {
            IfLetStore(
              store.scope(state: \.pickerState,
                          action: ApiAction.pickerAction
                         ),
              then: PickerView.init(store:)
            )
          }
        )
        
        // Login sheet
        .sheet(
          isPresented: viewStore.binding(
            get: { $0.loginState != nil },
            send: ApiAction.loginAction(.cancelButton)),
          content: {
            IfLetStore(
              store.scope(state: \.loginState,
                          action: ApiAction.loginAction
                         ),
              then: LoginView.init(store:)
            )
          }
        )
        
        // Connection sheet
        .sheet(
          isPresented: viewStore.binding(
            get: { $0.connectionState != nil },
            send: ApiAction.connectionAction(.cancelButton)),
          content: {
            IfLetStore(
              store.scope(state: \.connectionState,
                          action: ApiAction.connectionAction
                         ),
              then: ConnectionView.init(store:)
            )
          }
        )
        
      } else {
        LogView(store: Store(
          initialState: LogState(domain: viewStore.domain, appName: viewStore.appName, fontSize: viewStore.fontSize),
          reducer: logReducer,
          environment: LogEnvironment() )
        )
          .toolbar {
            Button("Api View") { viewStore.send(.apiViewButton) }
          }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct ApiView_Previews: PreviewProvider {
  static var previews: some View {
    ApiView(
      store: Store(
        initialState: ApiState(domain: "net.k3tzr", appName: "Api6000"),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975, minHeight: 400)
      .padding()
  }
}
