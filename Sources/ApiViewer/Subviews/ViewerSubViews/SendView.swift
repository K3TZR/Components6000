//
//  SendView.swift
//  Components6000/ApiViewer/Subviews/ViewerSubViews
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture
import Radio

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
//          Button("Send") { viewStore.radio!.removeTnf(1) }
//          Button("Send") { viewStore.radio!.requestTnf(at: 14300000) }
          .keyboardShortcut(.defaultAction)

          HStack(spacing: 0) {
            Image(systemName: "x.circle").foregroundColor(viewStore.radio == nil ? .gray : nil)
              .onTapGesture {
                viewStore.send(.commandTextField(""))
              }.disabled(viewStore.radio == nil)
            TextField("Command to send", text: viewStore.binding(
              get: \.commandToSend,
              send: { value in .commandTextField(value) } ))
          }
        }
        .disabled(viewStore.radio == nil)

        Spacer()
        Toggle("Clear on Send", isOn: viewStore.binding(get: \.clearOnSend, send: .toggle(\.clearOnSend)))
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
