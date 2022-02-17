//
//  FiltersView.swift
//  Components6000/ApiViewer/Subviews/ViewerSubViews
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
          send: { value in .objectsPicker(value) } )) {
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
          send: { value in .messagesPicker(value) } )) {
            ForEach(MessagesFilter.allCases, id: \.self) {
              Text($0.rawValue)
            }
          }
          .disabled(viewStore.radio == nil)
          .frame(width: 300)
        Image(systemName: "x.circle").foregroundColor(viewStore.radio == nil ? .gray : nil)
          .onTapGesture {
            viewStore.send(.messagesFilterTextField(""))
          }.disabled(viewStore.radio == nil)
        TextField("", text: viewStore.binding(
          get: \.messagesFilterByText,
          send: { value in ApiAction.messagesFilterTextField(value) }))
          .disabled(viewStore.radio == nil)
      }
    }
    .pickerStyle(MenuPickerStyle())
  }
}

struct FiltersView_Previews: PreviewProvider {

    static var previews: some View {
      FiltersView(
        store: Store(
          initialState: ApiState(),
          reducer: apiReducer,
          environment: ApiEnvironment()
        )
      )
    }
}
