//
//  LogBodyView.swift
//  
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
          ForEach(viewStore.logMessages) { entry in
            Text(entry.text)
              .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
              .foregroundColor(entry.color)
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
        initialState: LogState(domain: "net.k3tzr", appName: "Api6000"),
        reducer: logReducer,
        environment: LogEnvironment()
      )
    )
      .frame(minWidth: 975, minHeight: 400)
      .padding()
  }
}
