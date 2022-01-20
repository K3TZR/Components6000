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
  let defaultSelection: PickerSelection?

  @State var radioSelected = false
  @State var selectedStationIndex: Int?

  func parseStations(_ clients: IdentifiedArrayOf<GuiClient>) -> [String] {
    switch clients.count {
    case 1: return [clients[0].station, ""]
    case 2: return [clients[0].station, clients[1].station]
    default: return ["",""]
    }
  }

  func isDefault(_ store: ViewStore<Packet, PacketAction>) -> Bool {
    guard defaultSelection != nil else { return false }

    if let index = selectedStationIndex {
      return store.source == defaultSelection!.packet.source && store.serial == defaultSelection!.packet.serial && defaultSelection!.station == store.guiClients[index].station
    } else {
      return store.source == defaultSelection!.packet.source && store.serial == defaultSelection!.packet.serial && defaultSelection!.station == nil
    }
  }

  var body: some View {
    WithViewStore(self.store) { viewStore in
      ZStack {
        HStack(spacing: 0) {

          Group {
            Text(viewStore.source.rawValue)
            Text(viewStore.nickname)
            Text(viewStore.status)
          }
          .foregroundColor(isDefault(viewStore) ? .red : nil)
          .onTapGesture {
            radioSelected.toggle()
            if radioSelected {
              viewStore.send(.selection(PickerSelection(viewStore.state, nil)))
            } else {
              viewStore.send(.selection(nil))
            }
          }
          .disabled(pickType == .station)
          .font(.title3)
          .frame(width: 140, alignment: .leading)

          Group {
            ZStack {
              Text(parseStations(viewStore.guiClients)[0])
                .onTapGesture {
                  if selectedStationIndex != 0 {
                    selectedStationIndex = 0
                    viewStore.send(.selection(PickerSelection(viewStore.state,  viewStore.guiClients[selectedStationIndex!].station)))
                  } else {
                    selectedStationIndex = nil
                    viewStore.send(.selection(nil))
                  }
                }
                .disabled(pickType == .radio)

              Rectangle().fill(selectedStationIndex == 0 ? .gray : .clear).opacity(0.2)

            }
            ZStack {
              Text(parseStations(viewStore.guiClients)[1])
                .onTapGesture {
                  if selectedStationIndex != 1 {
                    selectedStationIndex = 1
                    viewStore.send(.selection(PickerSelection(viewStore.state, viewStore.guiClients[selectedStationIndex!].station)))
                  } else {
                    selectedStationIndex = nil
                    viewStore.send(.selection(nil))
                  }
                }
                .disabled(pickType == .radio)

              Rectangle().fill(selectedStationIndex == 1 ? .gray : .clear).opacity(0.2)
            }
          }
          .font(.title3)
          .frame(width: 140, alignment: .leading)        }
        Rectangle().fill(radioSelected ? .gray : .clear).frame(height: 20).opacity(0.2)
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
               pickType: .radio,
               defaultSelection: nil
    )
    .frame(minWidth: 700)
    .padding(.horizontal)
  }
}

