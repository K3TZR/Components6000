//
//  MessageView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture
import simd

// ----------------------------------------------------------------------------
// MARK: - View

struct MessagesView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    
    WithViewStore(self.store) { viewStore in
      ScrollView([.horizontal, .vertical]) {
        VStack(alignment: .leading) {
          if viewStore.reverse {
            ForEach(viewStore.filteredMessages.reversed(), id: \.id) { message in
              HStack {
                if viewStore.showTimes { Text("\(message.timeInterval)") }
                Text(message.text)
              }
              .foregroundColor( message.color )
            }
          } else {
            ForEach(viewStore.filteredMessages, id: \.id) { message in
              HStack {
                if viewStore.showTimes { Text("\(message.timeInterval)") }
                Text(message.text)
              }
              .foregroundColor( message.color )
            }
          }
        }
        .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
        .frame(minWidth: 12000, maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct MessagesView_Previews: PreviewProvider {
  static var previews: some View {
    MessagesView(
      store: Store(
        initialState: ApiState(domain: "net.k3tzr", appName: "Api6000"),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
