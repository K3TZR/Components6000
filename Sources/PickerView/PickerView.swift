//
//  PickerView.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/13/21.
//

import SwiftUI
import Combine
import ComposableArchitecture

import LanDiscovery
import ClientView
import Shared

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct PickerView: View {
  let store: Store<PickerState, PickerAction>
  
  public init(store: Store<PickerState, PickerAction>) {
    self.store = store
  }
  
  @State var selectedStation: String?
  
  /// Determine whether there are items to list
  /// - Parameter viewStore:     a viewStore
  /// - Returns:                 a Bool
  func noItemsToDisplay(_ viewStore: ViewStore<PickerState, PickerAction>) -> Bool {
    if viewStore.connectionType == .gui {
      return viewStore.packetCollection.packets.count == 0
    } else {
      for packet in viewStore.packetCollection.packets where packet.guiClients.count > 0 {
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
          PacketView(store: store)
        }
          Spacer()
          Divider()
          PickerFooterView(store: store)
      }
      .frame(minWidth: 600, minHeight: 250)

      // alert dialogs
      .alert(
        self.store.scope(state: \.alert),
        dismiss: .alertCancelled
      )      
    }
  }
}

public struct PacketView: View {
  let store: Store<PickerState, PickerAction>
  
  /// Create an array of station from the GuiClients array
  /// - Parameter guiClients:  an array of GuiClients
  /// - Returns:               an array of station names
  func parseStations(_ guiClients: IdentifiedArrayOf<GuiClient>) -> [String] {
    switch guiClients.count {
    case 1: return [guiClients[0].station, ""]
    case 2: return [guiClients[0].station, guiClients[1].station]
    default: return ["",""]
    }
  }
  
  public var body: some View {
    
    WithViewStore(store) { viewStore in
      ForEach(viewStore.packetCollection.packets, id: \.id) { packet in
        ZStack {
          HStack(spacing: 0) {
            Group {
              Text(packet.source.rawValue)
              Text(packet.nickname)
              Text(packet.status)
            }
            .disabled(viewStore.connectionType == .nonGui)
            .font(.title3)
            .frame(minWidth: 140, alignment: .leading)
            .foregroundColor(viewStore.defaultSelection?.packet == packet ? .red : nil)
            .onTapGesture {
              if viewStore.pickerSelection == PickerSelection(packet) {
                viewStore.send( .selection(nil) )
              }else {
                viewStore.send( .selection( PickerSelection(packet) ))
              }
            }
            Group {
              let stations = parseStations(packet.guiClients)
              ZStack {
                Text(stations[0])
                  .onTapGesture {
                    if viewStore.pickerSelection == PickerSelection(packet, stations[0]) {
                      viewStore.send( .selection(nil) )
                    } else {
                      viewStore.send( .selection(PickerSelection(packet, stations[0])) )
                    }
                  }
                  .disabled(viewStore.connectionType == .gui)
                Rectangle().fill(viewStore.pickerSelection == PickerSelection(packet,  stations[0]) ? .gray : .clear).opacity(0.2)
                
                Text(stations[1])
                  .onTapGesture {
                    if viewStore.pickerSelection == PickerSelection(packet, stations[1]) {
                      viewStore.send( .selection(nil) )
                    } else {
                      viewStore.send( .selection(PickerSelection(packet, stations[1])) )
                    }
                  }
                  .disabled(viewStore.connectionType == .gui)
                Rectangle().fill(viewStore.pickerSelection == PickerSelection(packet, stations[1]) ? .gray : .clear).opacity(0.2)                   }
            }
            .font(.title3)
            .frame(minWidth: 140, alignment: .leading)
          }
          Rectangle().fill(viewStore.pickerSelection?.packet == packet ? .gray : .clear).frame(height: 20).opacity(0.2)
        }
      }
      .padding(.horizontal)
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
      .previewDisplayName("Picker non Gui (empty)")
    
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

