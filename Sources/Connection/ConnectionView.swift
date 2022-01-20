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

public struct ConnectionView: View {
  let store: Store<ConnectionState,ConnectionAction>

  public init(store: Store<ConnectionState,ConnectionAction>) {
    self.store = store
  }

  //  private func close(_ selection: PickerSelection, _ station: String) -> PickerSelection {
  //    var selectionToClose = selection
  //    selectionToClose.station = station
  //    return selectionToClose
  //  }

  public var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack(spacing: 30) {
        Text("Choose an Action")
          .font(.title)
        Button( action: { viewStore.send(.disconnectThenConnect) })
        { Text("Close " + viewStore.pickerSelection.guiClients[0].station).frame(width: 150) }

        if viewStore.pickerSelection.guiClients.count == 1 {
          Button( action: { viewStore.send(.simpleConnect) })
          { Text("MultiFlex").frame(width: 150) }
        }

        if viewStore.pickerSelection.guiClients.count == 2 {
          Button( action: { viewStore.send(.disconnectThenConnect) })
          { Text("Close " + viewStore.pickerSelection.guiClients[1].station).frame(width: 150) }
        }

        Divider()

        Button( action: { viewStore.send(.cancelButton) })
        { Text("cancel") }
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

  var guiClients = IdentifiedArrayOf<GuiClient>()
  guiClients.append( GuiClient(clientHandle: 1, station: "iPad", program: "SmartSDR-iOS") )


  return PickerSelection(.local, "1234-5678-9012-3456", "newStation", guiClients)
}

private func testPickerSelection2() -> PickerSelection {

  var guiClients = IdentifiedArrayOf<GuiClient>()
  guiClients.append( GuiClient(clientHandle: 1, station: "iPad", program: "SmartSDR-iOS") )
  guiClients.append( GuiClient(clientHandle: 2, station: "Windows", program: "SmartSDR-Windows") )


  return PickerSelection(.local, "1234-5678-9012-3456", "newStation", guiClients)
}
