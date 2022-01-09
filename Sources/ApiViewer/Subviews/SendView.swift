//
//  SendView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

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
        Toggle("Clear on Send", isOn: viewStore.binding(get: \.clearOnSend, send: .button(\.clearOnSend)))
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct SendView_Previews: PreviewProvider {
  static var previews: some View {
    SendView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
