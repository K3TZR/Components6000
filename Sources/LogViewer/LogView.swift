//
//  LogView.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 10/10/20.
//  Copyright © 2020-2021 Douglas Adams. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

import Shared

// ----------------------------------------------------------------------------
// MARK: - View(s)

/// A View to display the contents of the app's log
///
public struct LogView: View {
  let store: Store<LogState, LogAction>
  
  public init(store: Store<LogState, LogAction>) {
    self.store = store
  }
  
  public var body: some View {
    
    WithViewStore(self.store) { viewStore in
      VStack {
        LogHeader(store: store)
        Divider().background(Color(.red))
        Spacer()
        LogBodyView(store: store)
        Spacer()
        Divider().background(Color(.red))
        LogFooter(store: store)
      }
      .frame(minWidth: 700)
      .toolbar {
        Button(viewStore.backName) { viewStore.send(.backButton) }
      }
      .alert(
        item: viewStore.binding(
          get: { $0.alert },
          send: .alertDismissed
        ),
        content: { Alert(title: Text($0.title)) }
      )

      .onAppear() { viewStore.send(.onAppear) }
    }
    //    .sheet(isPresented: $logManager.showLogPicker) {
    //      LogPickerView().environmentObject(logManager)
    //    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct LogView_Previews: PreviewProvider {
  static var previews: some View {
    LogView(
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
