//
//  LogFooterView.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct LogFooter: View {
  let store: Store<LogState, LogAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      HStack {
        Stepper("Font Size",
                value: viewStore.binding(
                  get: \.fontSize,
                  send: { value in .fontSize(value) }),
                in: 8...14)
        Text(String(format: "%2.0f", viewStore.fontSize)).frame(alignment: .leading)

        Spacer()
        Button("Email") { viewStore.send(.emailButton) }

        Spacer()
        HStack (spacing: 20) {
          Button("Refresh") { viewStore.send(.refreshButton) }.disabled(viewStore.logUrl == nil)
          Button("Load") { viewStore.send(.loadButton) }
          Button("Save") { viewStore.send(.saveButton) }
        }

        Spacer()
        Button("Clear") { viewStore.send(.clearButton) }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct LogFooter_Previews: PreviewProvider {
  static var previews: some View {
    LogFooter(
      store: Store(
        initialState: LogState(),
        reducer: logReducer,
        environment: LogEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
