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
        Button( action: { viewStore.send(.connect(viewStore.pickerSelection, viewStore.pickerSelection.packet.guiClients[0].handle)) })
        { Text("Close " + viewStore.pickerSelection.packet.guiClients[0].station.uppercased() + " Station").frame(width: 150) }

        if viewStore.pickerSelection.packet.guiClients.count == 1 {
          Button( action: { viewStore.send(.connect(viewStore.pickerSelection, nil)) })
          { Text("MultiFlex connect").frame(width: 150) }
        }

        if viewStore.pickerSelection.packet.guiClients.count == 2 {
          Button( action: { viewStore.send(.connect(viewStore.pickerSelection, viewStore.pickerSelection.packet.guiClients[0].handle)) })
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
      .previewDisplayName("Gui connect (disconnect not required)")

    ConnectionView(
      store: Store(
        initialState: ConnectionState( pickerSelection: testPickerSelection2() ),
        reducer: connectionReducer,
        environment: ConnectionEnvironment()
      )
    )
      .previewDisplayName("Gui connect (disconnect required)")
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
  packet.source = .local
  packet.serial = "5678-9012-3456-7890"
  packet.guiClients = [
    GuiClient(handle: 1, station: "iPad", program: "SmartSDR-iOS"),
  ]
  return packet
}

private func testPacket2() -> Packet {
  var packet = Packet()
  packet.nickname = "Dougs 6500"
  packet.source = .local
  packet.serial = "1234-5678-9012-3456"
  packet.guiClients = [
    GuiClient(handle: 1, station: "Windows", program: "SmartSDR-Windows"),
    GuiClient(handle: 2, station: "iPad", program: "SmartSDR-iOS")
  ]
  return packet
}
