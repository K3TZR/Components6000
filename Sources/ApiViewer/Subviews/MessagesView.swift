//
//  MessageView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct MessagesView: View {
  let store: Store<ApiState, ApiAction>

  var body: some View {

    WithViewStore(self.store) { viewStore in
      ScrollView([.horizontal, .vertical]) {
        LazyVStack(alignment: .leading) {
          ForEach(viewStore.commandMessages) { message in
            HStack {
              if viewStore.showTimes { Text("\(message.timeInterval)") }
              Text(message.text)
            }
              .foregroundColor( message.color )
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .frame(minWidth: 4000, maxWidth: .infinity, alignment: .leading)
        }
        .frame(alignment: .leading)
      }
      .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
      .frame(minHeight: 100, alignment: .leading)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct MessagesView_Previews: PreviewProvider {
  static var previews: some View {
    MessagesView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
