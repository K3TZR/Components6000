//
//  ViewModel.swift
//  
//
//  Created by Douglas Adams on 4/17/22.
//

import Foundation
import IdentifiedCollections

import Shared


final public class ViewModel: ObservableObject, Equatable {
  public static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
    lhs === rhs
  }
  
  
  @Published public var meters: IdentifiedArrayOf<Meter> = []
  @Published public var panadapters: IdentifiedArrayOf<Panadapter> = []
  @Published public var slices: IdentifiedArrayOf<Slice> = []
  @Published public var tnfs: IdentifiedArrayOf<Tnf> = []
  @Published public var waterfalls: IdentifiedArrayOf<Waterfall> = []

  // ----------------------------------------------------------------------------
  // MARK: - Singleton

  public static let shared = ViewModel()
  private init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

//  public func removeTnf(_ id: TnfId) {
//    Task {
//      await TnfCollection.shared.remove(id)
//    }
//  }
//
//  public func removeWaterfall(_ id: WaterfallId) {
//    Task {
//      await WaterfallCollection.shared.remove(id)
//    }
//  }
//
//  public func removePanadaapter(_ id: PanadapterId) {
//    Task {
//      await PanadapterCollection.shared.remove(id)
//    }
//  }
//
//  public func removeSlice(_ id: SliceId) {
//    Task {
//      await SliceCollection.shared.remove(id)
//    }
//  }
  
  public func removeObject<T>(_ id: T) {
    Task {
      switch id {
      case is MeterId:        await MeterCollection.shared.remove(id as! MeterId)
      case is PanadapterId:   await PanadapterCollection.shared.remove(id as! PanadapterId)
      case is SliceId:        await SliceCollection.shared.remove(id as! SliceId)
      case is TnfId:          await TnfCollection.shared.remove(id as! TnfId)
      case is WaterfallId:    await WaterfallCollection.shared.remove(id as! WaterfallId)
      default:                break
      }
    }
  }

}
