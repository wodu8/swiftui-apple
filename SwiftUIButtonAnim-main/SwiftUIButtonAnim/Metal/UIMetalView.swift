//
// Copyright (c) 2024, -  All rights reserved.
//
//

import Foundation

import MetalKit
import UIKit

protocol UIMetalViewDelegate {
  func updateFPS(fps: Double)
}

class UIMetalView: MTKView {
  var metalViewDelegate:UIMetalViewDelegate?
  var renderer: MTKViewRenderer? {
    didSet {
      delegate = renderer
    }
  
  }


//  var particleCount: Int = 100 {
//    didSet {
//      renderer?.particleCount = particleCount
//    }
//  }
//
//  var particleSize: Int = 10 {
//    didSet {
//      renderer?.particleSize = particleSize
//    }
//  }
//
//  var preferredFPS: Int = 60 {
//    didSet {
//      renderer?.preferredFPS = preferredFPS
//    }
//  }

  init() {
    // Metal device setup
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Metal is not supported on this device")
    }

    super.init(frame: .zero, device: device)

    enableSetNeedsDisplay = false

    clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

//
//  private func setup() {
//
//    layer.addSublayer(imageLayer)
//    layer.addSublayer(filterLayer)
//    filterLayer.addSublayer(shapeLayer)
//    filterLayer.addSublayer(imageFilterLayer)
//
//  }

  override func layoutSubviews() {
    super.layoutSubviews()
    print("layoutSubviews = \(frame)")
    update()
  }

  func update() {
//    renderer?.delegate = rendererDelegate
//    renderer?.update()
  }

//  override func draw(_ rect: CGRect) {
//    super.draw(rect)
//    print("draw = \(rect)")
//  }
}
