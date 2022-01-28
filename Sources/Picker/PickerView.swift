//
//  PickerView.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/13/21.
//

import SwiftUI
import Combine
import ComposableArchitecture

import Discovery
import Shared

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct PickerView: View {
  let store: Store<PickerState, PickerAction>
  
  public init(store: Store<PickerState, PickerAction>) {
    self.store = store
  }

  /// Determine whether there are items to list
  /// - Parameter viewStore:     a viewStore
  /// - Returns:                 a Bool
  func noItemsToDisplay(_ viewStore: ViewStore<PickerState, PickerAction>) -> Bool {
    if viewStore.connectionType == .gui {
      return viewStore.discovery.packets.count == 0
    } else {
      for packet in viewStore.discovery.packets where packet.guiClients.count > 0 {
       return false
      }
      return true
    }
  }

  public var body: some View {
    
    WithViewStore(store) { viewStore in
      VStack(alignment: .leading) {
        PickerHeaderView(connectionType: viewStore.connectionType)
        Divider()
        if noItemsToDisplay(viewStore) {
          Spacer()
          HStack {
            Spacer()
            Text("----------  NO  \(viewStore.connectionType.rawValue)s  FOUND  ----------").foregroundColor(.red)
            Spacer()
          }
          Spacer()
        } else {
          List {
            ForEachStore(
              self.store.scope(
                state: \.discovery.packets,
                action: PickerAction.packet(id:action:)
              )
            ) { packetStore in
              PacketView(store: packetStore,
                         connectionType: viewStore.connectionType,
                         defaultSelection: viewStore.defaultSelection
              )
            }
          }
        }
        Divider()
        PickerFooterView(store: store)
      }
      .frame(minWidth: 700, minHeight: 200, idealHeight: 300, maxHeight: 400)
      .onAppear { viewStore.send(.onAppear) }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct PickerView_Previews: PreviewProvider {
  static var previews: some View {

    PickerView(
      store: Store(
        initialState: PickerState(connectionType: .gui),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
      .previewDisplayName("Picker Gui (empty)")

    PickerView(
      store: Store(
        initialState: PickerState(connectionType: .gui),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
      .previewDisplayName("Picker Gui")

    PickerView(
      store: Store(
        initialState: PickerState(connectionType: .nonGui),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
      .previewDisplayName("Picker non Gui")
  }
}

// ----------------------------------------------------------------------------
// MARK: - Test data

func emptyTestPackets() -> [Packet] {
  return [Packet]()
}

func testPackets() -> [Packet] {
  var packets = [Packet]()
  
  packets.append(testPacket1())
  packets.append(testPacket2())

  return packets
}

func testPacket1() -> Packet {
  var packet = Packet()
  packet.nickname = "Dougs 6500"
  packet.status = "In Use"
  packet.serial = "1234-5678-9012-3456"
  packet.publicIp = "10.0.1.200"
  packet.guiClientHandles = "1,2"
  packet.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
  packet.guiClientStations = "Windows,iPad"
  packet.guiClientHosts = ""
  packet.guiClientIps = "192.168.1.200,192.168.1.201"

  return packet
}

func testPacket2() -> Packet {
  var packet = Packet()
  packet.nickname = "Dougs 6700"
  packet.status = "Available"
  packet.serial = "5678-9012-3456-7890"
  packet.publicIp = "40.0.2.278"
  packet.guiClientHandles = ""
  packet.guiClientPrograms = ""
  packet.guiClientStations = ""
  packet.guiClientHosts = ""
  packet.guiClientIps = ""

  return packet
}

