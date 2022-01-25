//
//  AtuView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct AtuView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        let atu = viewStore.radio!.atu!
        HStack(spacing: 20) {
          Text("ATU -> ").frame(width: 140, alignment: .leading)
          Text("").frame(width: 120, alignment: .leading)
          Text("Enabled \(atu.enabled ? "Y" : "N")")
          Text("Status \(atu.status)")
          Text("Memories enabled \(atu.memoriesEnabled ? "Y" : "N")")
          Text("Using memories \(atu.usingMemory ? "Y" : "N")")
        }.frame(maxWidth: .infinity, alignment: .leading)
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

struct AtuView_Previews: PreviewProvider {
  static var previews: some View {
    AtuView(
      store: Store(
        initialState: ApiState(
          domain: "net.k3tzr",
          appName: "Api6000",
          radio: Radio(Packet(),
                       connectionType: .gui,
                       command: TcpCommand(),
                       stream: UdpStream())
        ),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
