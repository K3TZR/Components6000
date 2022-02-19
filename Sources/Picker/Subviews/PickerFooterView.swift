//
//  PickerFooterView.swift
//  
//
//  Created by Douglas Adams on 1/9/22.
//

import SwiftUI
import ComposableArchitecture
import Discovery

// ----------------------------------------------------------------------------
// MARK: - View

struct PickerFooterView: View {
  let store: Store<PickerState, PickerAction>

  var body: some View {
    WithViewStore(store) { viewStore in

      HStack(){
        Button("Test") {viewStore.send(.testButton(viewStore.pickerSelection!))}
        .disabled(viewStore.pickerSelection == nil || viewStore.pickerSelection?.packet.source != .smartlink)
        Circle()
          .fill(viewStore.testResult?.success ?? false ? Color.green : Color.red)
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

//struct PickerFooterView_Previews: PreviewProvider {
//  static var previews: some View {
//    
//    PickerFooterView(store: Store(
//      initialState: PickerState(connectionType: .gui, testResult: testResultFail, discovery: LanDiscovery()),
//      reducer: pickerReducer,
//      environment: PickerEnvironment() )
//    )
//      .previewDisplayName("Test false")
//    
//    PickerFooterView(store: Store(
//      initialState: PickerState(connectionType: .nonGui, testResult: testResultSuccess1, discovery: LanDiscovery()),
//      reducer: pickerReducer,
//      environment: PickerEnvironment() )
//    )
//      .previewDisplayName("Test true (FORWARDING)")
//
//    PickerFooterView(store: Store(
//      initialState: PickerState(connectionType: .nonGui, testResult: testResultSuccess2, discovery: LanDiscovery()),
//      reducer: pickerReducer,
//      environment: PickerEnvironment() )
//    )
//      .previewDisplayName("Test true (UPNP)")
//  }
//}
//
//
//var testResultFail: SmartlinkTestResult {
//  SmartlinkTestResult()
//}
//
//var testResultSuccess1: SmartlinkTestResult {
//  var result = SmartlinkTestResult()
//  result.forwardTcpPortWorking = true
//  result.forwardUdpPortWorking = true
//  return result
//}
//
//var testResultSuccess2: SmartlinkTestResult {
//  var result = SmartlinkTestResult()
//  result.upnpTcpPortWorking = true
//  result.upnpUdpPortWorking = true
//  return result
//}
