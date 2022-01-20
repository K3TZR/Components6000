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
  let connectionType: ConnectionType
  let defaultSelection: PickerSelection?

  @State var radioSelected = false
  @State var selectedStation: String?

  /// Create an array of station fromthe GuiClients array
  /// - Parameter guiClients:  an array of GuiClients
  /// - Returns:               an array of station names
  func parseStations(_ store: ViewStore<Packet, PacketAction>) -> [String] {
    switch store.guiClients.count {
    case 1: return [store.guiClients[0].station, ""]
    case 2: return [store.guiClients[0].station, store.guiClients[1].station]
    default: return ["",""]
    }
  }

  func isDefault(_ store: ViewStore<Packet, PacketAction>) -> Bool {
    guard defaultSelection != nil else { return false }
    return store.source == defaultSelection!.packet.source && store.serial == defaultSelection!.packet.serial && defaultSelection!.station == selectedStation
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
          .disabled(connectionType == .nonGui)
          .font(.title3)
          .frame(width: 140, alignment: .leading)

          Group {
            let station = parseStations(viewStore)[0]
            ZStack {
              Text(station)
                .onTapGesture {
                  if selectedStation != station {
                    selectedStation = station
                    viewStore.send(.selection(PickerSelection(viewStore.state,  station)))
                  } else {
                    selectedStation = nil
                    viewStore.send(.selection(nil))
                  }
                }
                .disabled(connectionType == .gui)

              Rectangle().fill(selectedStation != nil && selectedStation == station ? .gray : .clear).opacity(0.2)

            }
            ZStack {
              let station = parseStations(viewStore)[1]
              Text(station)
                .onTapGesture {
                  if selectedStation != station {
                    selectedStation = station
                    viewStore.send(.selection(PickerSelection(viewStore.state,  station)))
                  } else {
                    selectedStation = nil
                    viewStore.send(.selection(nil))
                  }
                }
                .disabled(connectionType == .gui)

              Rectangle().fill(selectedStation != nil && selectedStation == station ? .gray : .clear).opacity(0.2)
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
               connectionType: .gui,
               defaultSelection: nil
    )
    .frame(minWidth: 700)
    .padding(.horizontal)
  }
}

