//
//  PickerFooterView.swift
//  
//
//  Created by Douglas Adams on 1/9/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct PickerFooterView: View {
  let store: Store<PickerState, PickerAction>

  var body: some View {
    WithViewStore(store) { viewStore in

      HStack(){
        Button("Test") {viewStore.send(.testButton(viewStore.pickerSelection!))}
        .disabled(viewStore.pickerSelection == nil || viewStore.pickerSelection?.source != .smartlink)
        Circle()
          .fill(viewStore.testStatus ? Color.green : Color.red)
          .frame(width: 20, height: 20)

        Spacer()
        Button("Default") {viewStore.send(.defaultButton(viewStore.pickerSelection!)) }
        .disabled(viewStore.pickerSelection == nil)
        .keyboardShortcut(.cancelAction)

        Spacer()
        Button("Cancel") {viewStore.send(.cancelButton) }
        .keyboardShortcut(.cancelAction)

        Spacer()
        Button("Connect") {viewStore.send(.connectButton(viewStore.pickerSelection!))}
        .keyboardShortcut(.defaultAction)
        .disabled(viewStore.pickerSelection == nil)
      }
    }
    .padding(.vertical, 10)
    .padding(.horizontal)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct PickerFooterView_Previews: PreviewProvider {
  static var previews: some View {
    
    PickerFooterView(store: Store(
      initialState: PickerState(pickType: .radio, testStatus: false),
      reducer: pickerReducer,
      environment: PickerEnvironment() )
    )
      .previewDisplayName("Test false")
    
    PickerFooterView(store: Store(
      initialState: PickerState(pickType: .radio, testStatus: true),
      reducer: pickerReducer,
      environment: PickerEnvironment() )
    )
      .previewDisplayName("Test true")
  }
}