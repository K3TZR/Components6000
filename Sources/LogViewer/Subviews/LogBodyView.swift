//
//  LogBodyView.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct LogBodyView: View {
  let store: Store<LogState, LogAction>

  var body: some View {

    WithViewStore(self.store) { viewStore in
      ScrollView([.horizontal, .vertical]) {
        VStack(alignment: .leading) {
          if viewStore.reversed {
            ForEach(Array(viewStore.logMessages.enumerated().reversed()), id: \.offset) { index, element in
              Text(element.text)
                .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
                .foregroundColor(element.color)
            }
          } else {
            ForEach(Array(viewStore.logMessages.enumerated()), id: \.offset) { index, element in
              Text(element.text)
                .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
                .foregroundColor(element.color)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct LogBodyView_Previews: PreviewProvider {
  static var previews: some View {
    LogBodyView(
      store: Store(
        initialState: LogState(),
        reducer: logReducer,
        environment: LogEnvironment()
      )
    )
      .frame(minWidth: 975, minHeight: 400)
      .padding()
  }
}
