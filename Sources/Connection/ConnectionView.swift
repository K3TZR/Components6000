//
//  ConnectionView.swift
//  
//
//  Created by Douglas Adams on 1/19/22.
//

import ComposableArchitecture
import SwiftUI

import Shared
import Picker

// ----------------------------------------------------------------------------
// MARK: - View(s)

// assumes that the number of GuiClients is 1 or 2

public struct ConnectionView: View {
  let store: Store<ConnectionState,ConnectionAction>

  public init(store: Store<ConnectionState,ConnectionAction>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Text("Choose an Action").font(.title)
        Text("for Radio <\(viewStore.pickerSelection.packet.nickname)>")
        Divider()
        Button( action: { viewStore.send(.disconnectThenConnect(viewStore.pickerSelection, 0)) })
        { Text("Close " + viewStore.pickerSelection.packet.guiClients[0].station.uppercased() + " Station").frame(width: 150) }

        if viewStore.pickerSelection.packet.guiClients.count == 1 {
          Button( action: { viewStore.send(.simpleConnect(viewStore.pickerSelection)) })
          { Text("MultiFlex connect").frame(width: 150) }
        }

        if viewStore.pickerSelection.packet.guiClients.count == 2 {
          Button( action: { viewStore.send(.disconnectThenConnect(viewStore.pickerSelection, 1)) })
          { Text("Close " + viewStore.pickerSelection.packet.guiClients[1].station.uppercased() + " Station").frame(width: 150) }
        }

        Divider()

        Button( action: { viewStore.send(.cancelButton) })
        { Text("Cancel") }
        .keyboardShortcut(.cancelAction)
      }
      .frame(maxWidth: 200)
      .padding()
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct ConnectionView_Previews: PreviewProvider {
  static var previews: some View {
    ConnectionView(
      store: Store(
        initialState: ConnectionState( pickerSelection: testPickerSelection1() ),
        reducer: connectionReducer,
        environment: ConnectionEnvironment()
      )
    )
    ConnectionView(
      store: Store(
        initialState: ConnectionState( pickerSelection: testPickerSelection2() ),
        reducer: connectionReducer,
        environment: ConnectionEnvironment()
      )
    )
  }
}

private func testPickerSelection1() -> PickerSelection {
  PickerSelection(testPacket1(), nil)
}

private func testPickerSelection2() -> PickerSelection {
  PickerSelection(testPacket2(), "newStation")
}

private func testPacket1() -> Packet {
  var packet = Packet()
  packet.nickname = "Dougs 6700"
//  packet.status = "Available"
  packet.source = .local
  packet.serial = "5678-9012-3456-7890"
//  packet.publicIp = "40.0.2.278"
//  packet.guiClientHandles = ""
//  packet.guiClientPrograms = ""
//  packet.guiClientStations = ""
//  packet.guiClientHosts = ""
//  packet.guiClientIps = ""
  packet.guiClients = [
    GuiClient(clientHandle: 1, station: "iPad", program: "SmartSDR-iOS"),
  ]
  return packet
}

private func testPacket2() -> Packet {
  var packet = Packet()
  packet.nickname = "Dougs 6500"
//  packet.status = "In Use"
  packet.source = .local
  packet.serial = "1234-5678-9012-3456"
//  packet.publicIp = "10.0.1.200"
//  packet.guiClientHandles = "1,2"
//  packet.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
//  packet.guiClientStations = "Windows,iPad"
//  packet.guiClientHosts = ""
//  packet.guiClientIps = "192.168.1.200,192.168.1.201"
  packet.guiClients = [
    GuiClient(clientHandle: 1, station: "Windows", program: "SmartSDR-Windows"),
    GuiClient(clientHandle: 2, station: "iPad", program: "SmartSDR-iOS")
  ]
  return packet
}
