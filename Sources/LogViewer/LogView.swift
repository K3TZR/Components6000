//
//  LogView.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 10/10/20.
//  Copyright © 2020-2021 Douglas Adams. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

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
        //      LogBodyView(logManager: logManager)
        Text("---------- Log Lines go here ----------")
          .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
        Spacer()
        Divider().background(Color(.red))
        LogFooter(store: store)
      }
      .frame(minWidth: 700)
      .toolbar {
        Button("Api View") { viewStore.send(.apiViewButton) }
      }
    }
    //    .onAppear() {
    //      logManager.loadDefaultLog()
    //    }
    //    .sheet(isPresented: $logManager.showLogPicker) {
    //      LogPickerView().environmentObject(logManager)
    //    }
  }
  
}

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
        }.frame(width: 175)
        
        Spacer()
        Picker("Filter by", selection: viewStore.binding(
          get: \.filterBy,
          send: { value in .filterBy(value) } )) {
          ForEach(LogFilter.allCases, id: \.self) {
            Text($0.rawValue)
          }
        }.frame(width: 175)
        
        TextField("Filter text", text: viewStore.binding(
          get: \.filterByText,
          send: { value in .filterByText(value) } ))
          .frame(maxWidth: 300, alignment: .leading)
        //                .modifier(ClearButton(boundText: $logManager.filterByText))
        
        Spacer()
        Toggle("Show Timestamps", isOn: viewStore.binding(get: \.showTimestamps, send: .timestampsButton))
      }
    }
  }
}

//struct LogBodyView: View {
//    @ObservedObject var logManager: LogManager
//
//    func lineColor(_ text: String) -> Color {
//        if text.contains("[Debug]") {
//            return .gray
//        } else if  text.contains("[Info]") {
//            return .primary
//        } else if  text.contains("[Warning]") {
//            return .orange
//        } else if  text.contains("[Error]") {
//            return .red
//        } else {
//            return .primary
//        }
//    }
//
//    var body: some View {
//        ScrollView([.horizontal, .vertical]) {
//            VStack(alignment: .leading) {
//                ForEach(logManager.logLines) { line in
//                    Text(line.text)
//                        .font(.system(size: CGFloat(logManager.fontSize), weight: .regular, design: .monospaced))
//                        .foregroundColor(lineColor(line.text))
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//    }
//}
//
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
          Button("Refresh") { viewStore.send(.refreshButton) }
          Button("Load") { viewStore.send(.loadButton) }
          Button("Save") { viewStore.send(.saveButton) }
        }
        
        Spacer()
        Button("Clear") { viewStore.send(.clearButton) }
      }
    }
  }
}

//public struct LogViewer_Previews: PreviewProvider {
//
//  public static var previews: some View {
//        LogViewer()
//    }
//}
