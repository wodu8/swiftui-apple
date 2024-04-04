//
// Copyright (c) 2024, - All rights reserved.
//
//

import Foundation

import SwiftUI
import MetalKit

var renderers:[ParticleRendererMetalPositoin] = []
var currentRenderer = 1

struct MetalView: UIViewRepresentable {
  @Binding var fps: Double
  
  var particleCount: Int = 100
  var particleSize: Int = 8
  var preferredFPS: Int = 60

  var image: UIImage

  func makeUIView(context: Context) -> MTKView {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Metal is not supported on this device")
    }


    let mtkView = MTKView(frame: .zero, device: device)
    mtkView.enableSetNeedsDisplay = false
    mtkView.clearColor = MTLClearColorMake(0.0, 0.6, 1.0, 1.0)
    mtkView.isPaused = false


    for size in [5,10,20]{
      let renderer  = ParticleRendererMetalPositoin(metalKitView: mtkView)
      renderer.particleSize = size
      renderers.append(renderer)
    }
    mtkView.delegate = renderers[currentRenderer]
    return mtkView
  }

  func updateUIView(_ mtkView: MTKView, context: Context) {
    print("MetalView(Representable) updateUIView currentRenderer=\(currentRenderer)")
//    renderer?.particleCount = particleCount
//    renderer?.particleSize = particleSize
//    renderer?.update()
    mtkView.preferredFramesPerSecond = preferredFPS
    
    for size in [5,10,20]{
      let renderer  = ParticleRendererMetalPositoin(metalKitView: mtkView)
      renderer.particleSize = size
      renderers.append(renderer)
    }
    
    currentRenderer = (currentRenderer + 1) % renderers.count
    mtkView.delegate = renderers[currentRenderer]

//    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//      print("MetalView(Representable) updateUIView 5 seconds later")
//      mtkView.delegate = nil
//    }
//    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//      print("MetalView(Representable) updateUIView 10 seconds later")
//      mtkView.delegate = renderer
//    }
    
//    renderer.preferredFPS = preferredFPS
//    uiView.renderer = renderer
//    renderer.update()
//    }
//    renderer.update()

//    uiView.cgImage = image.cgImage
//
//    var isUpdate = false
//    if uiView.particleCount != particleCount ||  uiView.preferredFPS != preferredFPS {
//      isUpdate =  true
//    }
//    uiView.particleCount = particleCount
//    uiView.particleSize = particleSize
//    uiView.preferredFPS = preferredFPS
//    if isUpdate {
//      uiView.update()
//    }
  }

//  func makeCoordinator() -> Coordinator {
//    return Coordinator(self)
//  }
  
  
//
//  class Coordinator: NSObject, MTKViewDelegate {
//    let contentView: MetalView
//
//    init(_ contentView: MetalView) {
//      self.contentView = contentView
//    }
//
//    func updateFPS(fps: Double) {
//      contentView.fps = fps
//    }
//  }
}
