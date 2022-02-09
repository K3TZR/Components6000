//
//  ObjectsView.swift
//  Components6000/ApiViewer/Subviews/ViewerSubViews
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct ObjectsView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      ScrollView([.horizontal, .vertical]) {
        LazyVStack {
          RadioView(store: store)
          if viewStore.isGui == true { GuiClientsView(store: store) }
          if viewStore.isGui == false { NonGuiClientView(store: store) }
        }
        .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
        .frame(minWidth: 4000, maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

import Radio
import TcpCommands
import UdpStreams
import Shared

struct ObjectsView_Previews: PreviewProvider {

  static var previews: some View {
    ObjectsView(
      store: Store(
        initialState: ApiState(
          domain: "net.k3tzr",
          appName: "Api6000",
          isGui: false,
          radio: Radio(testPacket,
                       connectionType: .gui,
                       command: Tcp(),
                       stream: Udp())
        ),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
      .previewDisplayName("----- Non Gui -----")

    ObjectsView(
      store: Store(
        initialState: ApiState(
          domain: "net.k3tzr",
          appName: "Api6000",
          isGui: true,
          radio: Radio(testPacket,
                       connectionType: .gui,
                       command: Tcp(),
                       stream: Udp())
        ),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
      .previewDisplayName("----- Gui -----")
  }
}
