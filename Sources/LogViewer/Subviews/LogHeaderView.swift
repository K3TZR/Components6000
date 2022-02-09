//
//  SwiftUIView.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

import Shared

// ----------------------------------------------------------------------------
// MARK: - View

struct LogHeader: View {
  let store: Store<LogState, LogAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      HStack {
        Picker("Show Level", selection: viewStore.binding(
          get: \.logLevel,
          send: { value in .logLevel(value) } )) {
          ForEach(LogLevel.allCases, id: \.self) {
            Text($0.rawValue)
          }
        }.disabled(viewStore.logUrl == nil)
          .frame(width: 175)

        Spacer()
        Picker("Filter by", selection: viewStore.binding(
          get: \.filterBy,
          send: { value in .filterBy(value) } )) {
          ForEach(LogFilter.allCases, id: \.self) {
            Text($0.rawValue)
          }
        }.disabled(viewStore.logUrl == nil)
          .frame(width: 175)

        TextField("Filter text", text: viewStore.binding(
          get: \.filterByText,
          send: { value in .filterByText(value) } ))
          .frame(maxWidth: 300, alignment: .leading)
        //                .modifier(ClearButton(boundText: $logManager.filterByText))

        Spacer()
        Toggle("Show Timestamps", isOn: viewStore.binding(get: \.showTimestamps, send: .timestampsButton)).disabled(viewStore.logUrl == nil)
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct LogHeader_Previews: PreviewProvider {
  static var previews: some View {
    LogHeader(
      store: Store(
        initialState: LogState(domain: "net.k3tzr", appName: "Api6000"),
        reducer: logReducer,
        environment: LogEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
