//
//  FiltersView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 8/10/20.
//

import SwiftUI
import ComposableArchitecture

struct FiltersView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    HStack(spacing: 100) {
      FilterObjectsView(store: store)
      FilterMessagesView(store: store)
    }
  }
}

struct FilterObjectsView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    
    WithViewStore(self.store) { viewStore in
      HStack {
        Picker("Show objects of type", selection: viewStore.binding(
          get: \.objectsFilterBy,
          send: { value in .objectsFilterBy(value) } )) {
            ForEach(ObjectsFilter.allCases, id: \.self) {
              Text($0.rawValue)
            }
          }
          .disabled(viewStore.radio == nil)
          .frame(width: 300)
      }
    }
    .pickerStyle(MenuPickerStyle())
  }
}

struct FilterMessagesView: View {
  let store: Store<ApiState, ApiAction>

  var body: some View {

    WithViewStore(self.store) { viewStore in
      HStack {
        Picker("Show messages of type", selection: viewStore.binding(
          get: \.messagesFilterBy,
          send: { value in .messagesFilterBy(value) } )) {
            ForEach(MessagesFilter.allCases, id: \.self) {
              Text($0.rawValue)
            }
          }
          .disabled(viewStore.radio == nil)
          .frame(width: 300)
        Image(systemName: "x.circle").foregroundColor(viewStore.radio == nil ? .gray : nil)
          .onTapGesture {
            viewStore.send(.messagesFilterByText(""))
          }.disabled(viewStore.radio == nil)
        TextField("", text: viewStore.binding(
          get: \.messagesFilterByText,
          send: { value in ApiAction.messagesFilterByText(value) }))
          .disabled(viewStore.radio == nil)
      }
    }
    .pickerStyle(MenuPickerStyle())
//      .onChange(of: object.messagesFilterBy, perform: { value in
//        object.filterUpdate(filterBy: value, filterText: object.messagesFilterText)
//      })
//      .frame(width: 275)
//
//      TextField("Filter text", text: object.$messagesFilterText)
//        .onChange(of: object.messagesFilterText, perform: { value in
//          object.filterUpdate(filterBy: object.messagesFilterBy, filterText: value)
//        })
//        .modifier(ClearButton(boundText: object.$messagesFilterText))
//    }
//    .pickerStyle(MenuPickerStyle())
  }
}

struct FiltersView_Previews: PreviewProvider {

    static var previews: some View {
      FiltersView(
        store: Store(
          initialState: ApiState(domain: "net.k3tzr", appName: "Api6000"),
          reducer: apiReducer,
          environment: ApiEnvironment()
        )
      )
    }
}
