//
//  LevelIndicatorView.swift
//  
//
//  Created by Douglas Adams on 4/29/22.
//

import Foundation
import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

public enum IndicatorStyle {
  case standard
  case standardFlipped
  case sMeter
}

public struct IndicatorParams {
  var width: CGFloat
  var height: CGFloat
  var warningPercent: CGFloat
  var criticalPercent: CGFloat
  var backgroundColor: Color
  var normalColor: Color
  var warningColor: Color
  var criticalColor: Color
  var borderColor: Color

  public init
  (
    width: CGFloat = 200,
    height: CGFloat = 20,
    warningPercent: CGFloat = 0.8,
    criticalPercent: CGFloat = 0.9,
    backgroundColor: Color = .clear,
    normalColor: Color = .blue,
    warningColor: Color = .yellow,
    criticalColor: Color = .red,
    borderColor: Color = .white
  )
  {
    self.width = width
    self.height = height
    self.warningPercent = warningPercent
    self.criticalPercent = criticalPercent
    self.backgroundColor = backgroundColor
    self.normalColor = normalColor
    self.warningColor = warningColor
    self.criticalColor = criticalColor
    self.borderColor = borderColor
  }
}

// ----------------------------------------------------------------------------
// MARK: - Views

public struct LevelIndicatorView: View {
  var level: CGFloat
  var style: IndicatorStyle
  var params: IndicatorParams

  public init(
    level: CGFloat,
    style: IndicatorStyle = .standard,
    params: IndicatorParams = IndicatorParams()
  )
  {
    self.level = level
    self.style = style
    self.params = params
  }
  
  public var body: some View {
  
    ZStack(alignment: .leading) {
      BarView(level: level, params: params)
      OutlineView(params: params)
    }
    .rotationEffect(.degrees( style == .standardFlipped ? 180 : 0))
  }
}

struct BarView: View {
  var level: CGFloat
  var params: IndicatorParams

  var body: some View {
    
    Rectangle()
      .frame(width: params.width * level, height:params.height)
      .foregroundColor(.blue)
  }
}
      
struct OutlineView: View {
  var params: IndicatorParams
  
  var body: some View {
    
    Rectangle()
      .frame(width: params.width, height: params.height)
      .foregroundColor(params.backgroundColor)
      .border(params.borderColor)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Previews

struct LevelIndicatorView_Previews: PreviewProvider {
  static var previews: some View {
    LevelIndicatorView(level: 0.4)
    LevelIndicatorView(level: 0.4, style: .standardFlipped)
  }
}

struct BarView_Previews: PreviewProvider {
    static var previews: some View {
      BarView(level: 0.4, params: IndicatorParams())
    }
}

struct OutlineView_Previews: PreviewProvider {
    static var previews: some View {
      OutlineView(params: IndicatorParams())
    }
}
