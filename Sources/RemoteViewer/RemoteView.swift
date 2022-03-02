//
//  RemoteView.swift
//  Components6000/DinRelay
//
//  Created by Douglas Adams on 2/26/22.
//

import ComposableArchitecture
import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct RemoteView: View {
  let store: Store<RemoteState, RemoteAction>
  
  public init(store: Store<RemoteState, RemoteAction>) {
    self.store = store
  }
  
  public var body: some View {
    
    WithViewStore(store) { viewStore in
      VStack {
        Text(viewStore.heading).font(.title).padding(.vertical)
        HStack {
          Text("Number").frame(width: 100, alignment: .leading)
          Text("Name").frame(width: 250, alignment: .leading)
          Text("State").frame(width: 100, alignment: .center)
          Text("Locked").frame(width: 100, alignment: .center)
          Text("Cycle Delay").frame(width: 150, alignment: .center)
        }.font(.title2)
        
        Divider().background(Color(.red))
        ForEach(viewStore.relays.indices) { index in
          HStack {
            VStack {
              Text("\(index + 1)")
            }.frame(width: 100, alignment: .leading)

            VStack {
              Text(viewStore.relays[index].name == "" ? "-- none --" : viewStore.relays[index].name)
            }.frame(width: 250, alignment: .leading)

            VStack {
              Toggle("", isOn: viewStore.binding(get: \.relays[index].state, send: .toggleState(index)))
            }.frame(width: 100, alignment: .center)
            
            VStack {
              Toggle("", isOn: viewStore.binding(get: \.relays[index].locked, send: .toggleLocked(index)))
            }.frame(width: 100, alignment: .center)
          
            VStack {
              Text(viewStore.relays[index].cycleDelay == nil ? "-- none --" : "\(viewStore.relays[index].cycleDelay!)")
            }.frame(width: 150, alignment: .center)
          }
          .font(.title2)
        }
        Spacer()
        Divider().background(Color(.red))
        HStack(spacing: 60) {
          Button("Refresh") { viewStore.send(.refresh) }
          Button("All Off") { viewStore.send(.allOff) }
          Spacer()
          Button("Start") { viewStore.send(.start) }
          Button("Stop") { viewStore.send(.stop) }
        }
        .onAppear() { viewStore.send(.onAppear) }
      }
      .padding()
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct RemoteView_Previews: PreviewProvider {
  
  static var previews: some View {
    RemoteView(
      store: Store(
        initialState: RemoteState("Test Relays"),
        reducer: remoteReducer,
        environment: RemoteEnvironment()
      )
    )
  }
}

public var testRelays: [Relay] = [
  Relay(name: "Main power"),
  Relay(name: "---"),
  Relay(name: "---"),
  Relay(name: "---"),
  Relay(name: "Astron power"),
  Relay(name: "Rotator power"),
  Relay(name: "Linear power"),
  Relay(name: "Remote power on")
]
