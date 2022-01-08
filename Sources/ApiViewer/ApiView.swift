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

public struct AlertView: Equatable, Identifiable {
  public var title: String
  public var id: String { self.title }
}

// ----------------------------------------------------------------------------
// MARK: - View

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

// ----------------------------------------------------------------------------
// MARK: - Preview

struct ApiView_Previews: PreviewProvider {
  static var previews: some View {
    ApiView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975, minHeight: 400)
      .padding()
  }
}
