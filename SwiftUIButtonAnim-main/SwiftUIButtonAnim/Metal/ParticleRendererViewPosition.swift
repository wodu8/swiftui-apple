//
// Copyright (c) 2024, - All rights reserved.
//
//

import Foundation
import MetalKit


// ViewのサイズでParticleを配置するバージョン。metalで位置を変換するので、やや遅いかも

class ParticleRendererViewPosition: NSObject {
  
  private var device: MTLDevice
  private var computePipelineState: MTLComputePipelineState
  
  private var pipelineState: MTLRenderPipelineState
  private var commandQueue: MTLCommandQueue

  private var particleCount = 100_000
//  private var vertexBuffer: MTLBuffer!
//  private var uniformBuffer: MTLBuffer!

  private var viewportSize: CGSize = .zero
  private var computeSemaphore: DispatchSemaphore
  
//  triple buffering
  //  GPUが現在のフレームを描画している間に、CPUが次のフレームの描画データを準備できるようにする
  //
  let kMaxInflightBuffers: Int = 3
  var frameBoundarySemaphore: DispatchSemaphore
  var currentFrameIndex: Int = 0
  var dynamicDataBuffers: [MTLBuffer] = []
  
  
  var no:Int = 0

  

  /// Background color of MTKView
  private var viewClearColor: MTLClearColor = .init(red: 0.0, green: 0.0, blue: 0.1, alpha: 0.0)

  init(metalKitView mtkView: MTKView) {
    print("ParticleRenderer init")
    if mtkView.device == nil {
      fatalError("Device not created. Run on a physical device")
    }

    self.device = mtkView.device!
    self.computeSemaphore = DispatchSemaphore(value: 1)
    
    

    frameBoundarySemaphore = DispatchSemaphore(value: Int(kMaxInflightBuffers))

    

    guard let library = device.makeDefaultLibrary() else {
      fatalError("Failed to create library")
    }
    guard let computeFunction = library.makeFunction(name: "particleViewPositionCompute") else {
      fatalError("Failed to create vertex function")
    }

    guard let vertexFunction = library.makeFunction(name: "particleViewPositionVertex") else {
      fatalError("Failed to create vertex function")
    }
    guard let fragmentFunction = library.makeFunction(name: "particleViewPositionFragment") else {
      fatalError("Failed to create fragment function")
    }
    
    
//    let computePipelineDescriptor = MTLComputePipelineDescriptor()
//    computePipelineDescriptor.computeFunction = computeFunction
//    computePipelineDescriptor.label = "ParticleCompute"
    // Compute Pipeline Stateの作成
    guard let computePipelineState = try? device.makeComputePipelineState(function: computeFunction)
            
      else {
        fatalError("Failed to create compute pipeline state")
    }
    self.computePipelineState = computePipelineState
    

    

    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "ParticlePipeline"
//    pipelineStateDescriptor.sampleCount = mtkView.sampleCount

    pipelineStateDescriptor.vertexFunction = vertexFunction
    pipelineStateDescriptor.fragmentFunction = fragmentFunction
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

    do {
      self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      fatalError("Failed to create pipeline state \(error)")
    }

    guard let queue = device.makeCommandQueue() else {
      fatalError("Failed to create command queue")
    }
    
    self.commandQueue = queue
    print("ParticleRenderer init finish")

    let length = MemoryLayout<Particle>.stride * particleCount

    super.init()

    
    mtkView.preferredFramesPerSecond = 60

    
//    var particles = [Particle]()
//    for _ in 0 ..< particleCount {
////      let position = SIMD2<Float>(Float.random(in: 999...1000), Float.random(in: 999...1000))
//      let position = SIMD2<Float>(600, 000)
//      let velocity = SIMD2<Float>(Float.random(in: -10...10), Float.random(in: -10...10))
////        let color = SIMD4<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), 1.0)
//      let color = SIMD4<Float>(1, 0, 0, 1)
//      particles.append(Particle(position: position, velocity: velocity, color: color))
//    }

//    let particles = [Particle(position: [0,100], velocity: [1,1], color: [1,1,1,1]),
//                     Particle(position: [200,0], velocity: [1,1], color: [1,1,1,1]),
//                     Particle(position: [300,300], velocity: [1,1], color: [1,1,1,1]),
//                     Particle(position: [400,400], velocity: [1,1], color: [1,1,1,1]),
//                     Particle(position: [500,500], velocity: [1,1], color: [1,1,1,1]),
//                     Particle(position: [600,600], velocity: [1,1], color: [1,1,1,1]),
//                     Particle(position: [700,700], velocity: [1,1], color: [1,1,1,1]),
//                     Particle(position: [800,800], velocity: [1,1], color: [1,1,1,1]),
//    ]
//

//    guard let buffer = device.makeBuffer(length: length,
//                                         options: [.storageModeShared])
//    else {
//      fatalError("Failed to create buffer")
//    }
//
//    self.vertexBuffer = buffer
    
    

    var mutableDynamicDataBuffers: [MTLBuffer] = []
    for _ in 0..<kMaxInflightBuffers {
      guard let dynamicDataBuffer = device.makeBuffer(length: length, options: [.storageModeShared])
      else {
        fatalError("Failed to create buffer")
      }
      mutableDynamicDataBuffers.append(dynamicDataBuffer)
    }
    dynamicDataBuffers = mutableDynamicDataBuffers
    
    currentFrameIndex = 0


    
//    let pointer = vertexBuffer.contents().bindMemory(to: Particle.self,
//                                                     capacity: particleCount)

//    for i in 0 ..< particleCount {
//      pointer[i] = Particle()
//
//      pointer[i].position = SIMD2<Float>(Float.random(in: -1...1),
//                                         Float.random(in: -1...1))
    ////      pointer[i].velocity = SIMD2<Float>(Float.random(in: -0.01...0.01),
    ////                                          Float.random(in: -0.01...0.01))
    ////
    ////      pointer[i].position = SIMD2<Float>(5.0, 5.0)
//      pointer[i].velocity = SIMD2<Float>(Float.random(in: -0.01...0.01),
//                                         Float.random(in: -0.01...0.01))
//
    ////      pointer[i].color = SIMD4<Float>(Float.random(in: 0...0),
    ////                                      Float.random(in: 0...0),
    ////                                      Float.random(in: 0.5...1),
    ////                                      1)
//      pointer[i].color = SIMD4<Float>(0,0,0.9,1)
//
//      print("Particle[\(i)]: \(pointer[i].position) \(pointer[i].velocity) \(pointer[i].color)")
//    }
  }
}

extension ParticleRendererViewPosition: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    print("ParticleRenderer drawableSizeWillChange \(size) currentFrameIndex=\(currentFrameIndex)")

    viewportSize = size

  
    let pointer = dynamicDataBuffers[currentFrameIndex].contents().bindMemory(to: Particle.self,
                                                     capacity: particleCount)

    let minX = -1.0 * Float(size.width) / 2.0
    let maxX = Float(size.width) / 2.0
    let minY = -1.0 * Float(size.height) / 2.0
    let maxY = Float(size.height) / 2.0

    
    for i in 0 ..< particleCount {
      pointer[i] = Particle()
//      pointer[i].position = SIMD2<Float>(Float(size.width) / 2.0, Float(size.height) / 2.0)

      pointer[i].position = SIMD2<Float>(x: Float.random(in: minX...maxX), 
                                         y: Float.random(in: minY...maxY))
      
      
      //      pointer[i].velocity = SIMD2<Float>(Float.random(in: -0.01...0.01),
      //                                          Float.random(in: -0.01...0.01))
      //
      //      pointer[i].position = SIMD2<Float>(5.0, 5.0)
      pointer[i].velocity = SIMD2<Float>(Float.random(in: -1...1),
                                         Float.random(in: -1...1))

      pointer[i].color = SIMD4<Float>(Float.random(in: 0.1...1),
                                      Float.random(in: 0.1...1),
                                      Float.random(in: 0.5...1),
                                      1)
//      pointer[i].color = SIMD4<Float>(1, 0, 0, 1)

//      print("Particle[\(i)]: \(pointer[i].position) \(pointer[i].velocity) \(pointer[i].color)")
    }
  }

  func update() {
    
    computeSemaphore.wait()
    
    // Pass in the parameter data.
    let currentBuffer = dynamicDataBuffers[currentFrameIndex]
    // 次のバッファを更新する
    currentFrameIndex = (currentFrameIndex + 1) % kMaxInflightBuffers
    let nextBuffer = dynamicDataBuffers[currentFrameIndex]

    
    var vSize = vector_float2(Float(viewportSize.width) / 1.0,
                                     Float(viewportSize.height) / 1.0)
    
    // Create a new command buffer for each render pass to the current drawable.
    guard let computeCommandBuffer = commandQueue.makeCommandBuffer() else { return }
    computeCommandBuffer.label = "MyCommand"
    
    let computeEncoder = computeCommandBuffer.makeComputeCommandEncoder()!
    computeEncoder.setComputePipelineState(computePipelineState)
    computeEncoder.setBuffer(currentBuffer, offset: 0, index: 0)
    computeEncoder.setBuffer(nextBuffer, offset: 0, index: 1)
    computeEncoder.setBytes(&vSize, length: MemoryLayout<vector_float2>.stride, index: 2)

        // スレッドグループサイズの設定
    let threadsPerThreadgroup = MTLSize(width: 64, height: 1, depth: 1)
    let numThreadgroups = MTLSize(width: (particleCount + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                   height: 1,
                                   depth: 1)

    computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()

    computeCommandBuffer.commit()
    computeCommandBuffer.waitUntilCompleted()
    
    computeSemaphore.signal()
    
  }
  
  func draw(in view: MTKView) {
    
    let drawno = no + 1
    self.no = drawno

    
//    print("ParticleRenderer draw[\(drawno)] \(viewportSize) currentFrameIndex=\(currentFrameIndex)")
    
    let _ = frameBoundarySemaphore.wait(timeout: DispatchTime.distantFuture)

    let currentBuffer = dynamicDataBuffers[currentFrameIndex]
//    print("currentBuffer[0]=\(currentBuffer[0])")
    
    var vSize = vector_float2(Float(viewportSize.width) / 1.0,
                                     Float(viewportSize.height) / 1.0)
    
    // slow function emulate
//    usleep(1_000_000 * 5 )
    update()
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures.
//    guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
    guard let renderCommandBuffer = commandQueue.makeCommandBuffer() else { return }
    renderCommandBuffer.label = "MyCommand"
   
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = view.currentDrawable?.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = viewClearColor
    renderPassDescriptor.colorAttachments[0].storeAction = .store

    // Create a render command encoder.
    guard let renderEncoder = renderCommandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
    renderEncoder.label = "MyRenderEncoder"

    // Set the region of the drawable to draw into.
    renderEncoder.setViewport(
      MTLViewport(originX: 0.0,
                  originY: 0.0,
                  width: Double(viewportSize.width),
                  height: Double(viewportSize.height),
                  znear: 0.0, zfar: 1.0))

    renderEncoder.setRenderPipelineState(pipelineState)

    // Pass in the parameter data.
    renderEncoder.setVertexBuffer(currentBuffer, offset: 0, index: 0)
    

//
//    renderEncoder.setVertexBytes(triangleVertices, length: MemoryLayout<AAPLVertex>.stride * triangleVertices.count, index: Int(AAPLVertexInputIndexVertices.rawValue))

    
//    print("viewportSize \(viewportSize)")

    renderEncoder.setVertexBytes(&vSize, length: MemoryLayout<vector_float2>.stride, index: 1)

    renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)

    renderEncoder.endEncoding()

    // Schedule a present once the framebuffer is complete using the current drawable.
    if let drawable = view.currentDrawable {
      renderCommandBuffer.present(drawable)
    }
    renderCommandBuffer.addCompletedHandler { _ in
      self.frameBoundarySemaphore.signal()
      
//      print("ParticleRenderer draw[\(drawno)] render complete.")
    }

    // Finalize rendering here & push the command buffer to the GPU.
    renderCommandBuffer.commit()
    
//    print("ParticleRenderer draw[\(drawno)] exit")

  }
}
