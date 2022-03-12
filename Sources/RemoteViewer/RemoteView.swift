//
//  RemoteView.swift
//  Components6000/RemoteViewer
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
        
        RemoteViewHeading(store: store)
        
        List {
          ForEachStore(
            self.store.scope(state: \.relays, action: RemoteAction.relay(id:action:)),
            content: RelayView.init(store:)
          )
        }

        RemoteViewFooter(store: store)
      }
      .onAppear() { viewStore.send(.onAppear) }
      .padding()
    }
  }
}

public struct RemoteViewHeading: View {
  let store: Store<RemoteState, RemoteAction>
  
  public var body: some View {
    
    WithViewStore(store) { viewStore in
      Text(viewStore.heading).font(.title).padding(.vertical)
      Text("- - - - - - - - - State - - - - - - - - -").font(.title2).frame(alignment: .leading).padding(.trailing, 70)
      HStack {
        Text("Name")
          .frame(width: 250, alignment: .leading)
        Group {
          Text("Physical")
          Text("Transient")
          Text("Current")
          Text("Critical")
          Text("Locked")
          Text("Cycle Delay")
        }
        .frame(width: 100, alignment: .center)
        .font(.title2)
      }
      Divider().background(Color(.red))
    }
  }
}

public struct RemoteViewFooter: View {
  let store: Store<RemoteState, RemoteAction>
  
  public var body: some View {
    
    WithViewStore(store) { viewStore in
      Spacer()
      Divider().background(Color(.red))
      HStack(spacing: 60) {
        Button("Refresh") { viewStore.send(.refresh) }.disabled(viewStore.scriptInFlight)
        Button("All Off") { viewStore.send(.allOff) }.disabled(viewStore.scriptInFlight)
        Spacer()
        Button("Cycle ON") { viewStore.send(.cycleOn) }.disabled(viewStore.scriptInFlight)
        Button("Cycle OFF") { viewStore.send(.cycleOff) }.disabled(viewStore.scriptInFlight)
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct RemoteView_Previews: PreviewProvider {
  
  static var previews: some View {
    RemoteView(
      store: Store(
        initialState: RemoteState("Relay Status"),
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
