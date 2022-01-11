//
//  PacketView.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/22/21.
//

import SwiftUI
import ComposableArchitecture

import Shared

// ----------------------------------------------------------------------------
// MARK: - View(s)

struct PacketView: View {
  let store: Store<Packet, PacketAction>
  let pickType: PickType

  @State var radioSelected = false
  @State var firstStationSelected = false
  @State var secondStationSelected = false

  func parseStations(_ clients: IdentifiedArrayOf<GuiClient>) -> [String] {
    switch clients.count {
    case 1: return [clients[0].station, ""]
    case 2: return [clients[0].station, clients[1].station]
    default: return ["",""]
    }
  }

  var body: some View {
    WithViewStore(self.store) { viewStore in
      ZStack {
        HStack(spacing: 0) {
          Button(action: { viewStore.send(.defaultButton) }) {
            Image(systemName: viewStore.isDefault ? "checkmark.square" : "square")
          }
          .buttonStyle(PlainButtonStyle())
          .labelsHidden()
          .frame(width: 95, alignment: .leading)

          Group {
            Text(viewStore.source.rawValue)
            Text(viewStore.nickname)
            Text(viewStore.status)
          }
          .onTapGesture { radioSelected.toggle() ; viewStore.send(.selection(radioSelected, nil))}
          .disabled(pickType == .station)
          .font(.title3)
          .frame(width: 140, alignment: .leading)

          Group {
            ZStack {
              Text(parseStations(viewStore.guiClients)[0])
                .onTapGesture { firstStationSelected.toggle() ; viewStore.send(.selection(firstStationSelected, 0))}
                .disabled(pickType == .radio)

              Rectangle().fill(firstStationSelected ? .gray : .clear).frame(width: 70, height: 20).opacity(0.2)
            }
            ZStack {
              Text(parseStations(viewStore.guiClients)[1])
                .onTapGesture { secondStationSelected.toggle() ; viewStore.send(.selection(secondStationSelected, 1))}
                .disabled(pickType == .radio)
              Rectangle().fill(secondStationSelected ? .gray : .clear).frame(width: 70, height: 20).opacity(0.2)
            }
          }
          .font(.title3)
          .frame(width: 140, alignment: .leading)        }
        Rectangle().fill(radioSelected ? .gray : .clear).frame(width: 500, height: 20).opacity(0.2)
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct PacketView_Previews: PreviewProvider {
  static var previews: some View {
    PacketView(store: Store(
      initialState: testPacket1(),
      reducer: packetReducer,
      environment: PacketEnvironment() ),
               pickType: .radio
    )
    .frame(minWidth: 700)
    .padding(.horizontal)
  }
}

