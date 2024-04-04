//
// Copyright (c) 2024, - All rights reserved.
//
//

import Foundation
import MetalKit

protocol MTKViewRendererDelegate:AnyObject {
  func renderer(_ renderer: ParticleRendererMetalPositoin, didUpdateFPS fps: Double)
}

protocol MTKViewRenderer: MTKViewDelegate {

//  init(metalKitView: UIMetalView)
//  func update()
////  var mtkView: MTKView { get }
//  var delegate: MTKViewRendererDelegate? { get set }
}

//
//// protocol MetalViewRenderer のFPS計算を共通関数化する。
//extension MetalViewRenderer {
//  func updateFPS(last):CACurrentMediaTime {
//    frameCount += 1
//    if startTime == nil {
//      startTime = CACurrentMediaTime()
//    } else {
//      let elapsed = CACurrentMediaTime() - startTime!
//      if elapsed >= 1.0 {
//        let fps = Double(frameCount) / elapsed
//        delegate?.renderer(self, didUpdateFPS: fps)
//        frameCount = 0
//        startTime = CACurrentMediaTime()
//      }
//    }
//  }
//}

// Metalの空間（-1.0 - 1.0）でParticleを配置するバージョン

class ParticleRendererMetalPositoin:NSObject {
  weak var delegate: (any MTKViewRendererDelegate)?
  private weak var mtkView: MTKView!
//  private weak var device: MTLDevice!
  private var makeParticlePipelineState: MTLComputePipelineState!
  private var computeParticlePipelineState: MTLComputePipelineState!

  private var pipelineState: MTLRenderPipelineState!
  private var commandQueue: MTLCommandQueue!

  var particleCount: Int = 10000 {
    didSet {
      if oldValue > 0 {
        if oldValue != particleCount {
          print("ParticleRendererMetalPositoin particleCount didSet changed")
          update()
        }
      }
    }
  }

  var particleSize: Int = 8
  var preferredFPS: Int = 60 {
    didSet {
      if oldValue != preferredFPS {
        print("ParticleRendererMetalPositoin preferredFPS didSet changed")
        mtkView.preferredFramesPerSecond = preferredFPS
      }
    }
  }

//  private var vertexBuffer: MTLBuffer!
//  private var uniformBuffer: MTLBuffer!

  private var viewportSize: CGSize = .zero
  private var computeSemaphore: DispatchSemaphore!

  private var startTime: CFTimeInterval?
  private var frameCount: Int = 0

//  triple buffering
  //  GPUが現在のフレームを描画している間に、CPUが次のフレームの描画データを準備できるようにする
  //
  let kMaxInflightBuffers: Int = 3
  var frameBoundarySemaphore: DispatchSemaphore!
  var currentFrameIndex: Int = 0
  var dynamicDataBuffers: [MTLBuffer] = []
//  var debugBuffer: MTLBuffer!
  var no: Int = 0

  /// Background color of MTKView
  private var viewClearColor: MTLClearColor = .init(red: 0.0, green: 0.0, blue: 0.1, alpha: 0.0)

  required init(metalKitView: MTKView) {
    super.init()
    
    print("ParticleRenderer init")
    if metalKitView.device == nil {
      fatalError("Device not created. Run on a physical device")
    }

    self.mtkView = metalKitView
//    self.device = mtkView.device!
    
    self.computeSemaphore = DispatchSemaphore(value: 1)

    frameBoundarySemaphore = DispatchSemaphore(value: Int(kMaxInflightBuffers))

    guard let device = mtkView.device else {
      fatalError("Device not created. Run on a physical device")
    }
//    self.device = device

    guard let library = device.makeDefaultLibrary() else {
      fatalError("Failed to create library")
    }
    guard let makeParticleFunction = library.makeFunction(name: "particleMetalPositionMake") else {
      fatalError("Failed to create vertex function")
    }

    guard let computeParticleFunction = library.makeFunction(name: "particleMetalPositionCompute") else {
      fatalError("Failed to create vertex function")
    }

    guard let vertexFunction = library.makeFunction(name: "particleMetalPositionVertex") else {
      fatalError("Failed to create vertex function")
    }
    guard let fragmentFunction = library.makeFunction(name: "particleMetalPositionFragment") else {
      fatalError("Failed to create fragment function")
    }

    // ---------------------
    // make Pipeline Stateの作成
    guard let makeParticlePipelineState = try? device.makeComputePipelineState(function: makeParticleFunction)

    else {
      fatalError("Failed to create compute pipeline state")
    }
    self.makeParticlePipelineState = makeParticlePipelineState
    print("makeParticlePipelineState maxTotalThreadsPerThreadgroup=\(makeParticlePipelineState.maxTotalThreadsPerThreadgroup) threadExecutionWidth=\(makeParticlePipelineState.threadExecutionWidth)")

    // ---------------------
    // Compute Pipeline Stateの作成
    guard let computeParticlePipelineState = try? device.makeComputePipelineState(function: computeParticleFunction)

    else {
      fatalError("Failed to create compute pipeline state")
    }
    self.computeParticlePipelineState = computeParticlePipelineState
    print("computeParticlePipelineState maxTotalThreadsPerThreadgroup=\(computeParticlePipelineState.maxTotalThreadsPerThreadgroup) threadExecutionWidth=\(computeParticlePipelineState.threadExecutionWidth)")

    // ---------------------
    // RenderPipelineの作成

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

//    super.init()

//    let length = MemoryLayout<Particle>.stride * particleCount
//    mtkView.preferredFramesPerSecond = preferredFPS
//
//    var mutableDynamicDataBuffers: [MTLBuffer] = []
//    for _ in 0 ..< kMaxInflightBuffers {
//      guard let dynamicDataBuffer = device.makeBuffer(length: length, options: [.storageModeShared])
//      else {
//        fatalError("Failed to create buffer")
//      }
//      mutableDynamicDataBuffers.append(dynamicDataBuffer)
//    }
//    dynamicDataBuffers = mutableDynamicDataBuffers
//
//    currentFrameIndex = 0
//
//    // debug buffer
//    guard let debugBuffer = device.makeBuffer(
//      length: MemoryLayout<ParticleDebug>.stride * particleCount,
//      options: [.storageModeShared])
//    else {
//      fatalError("Failed to create debug buffer")
//    }
//    self.debugBuffer = debugBuffer
//
//    makeParticlesGPU()
   
    update()
  }

  func update() {
    guard let device = mtkView.device else {
      fatalError("Device not created. Run on a physical device")
    }
    
    print("ParticleRenderer update \(particleCount) \(particleSize) \(preferredFPS)")
    mtkView.preferredFramesPerSecond = preferredFPS

    let length = MemoryLayout<Particle>.stride * particleCount
    mtkView.preferredFramesPerSecond = preferredFPS

    var mutableDynamicDataBuffers: [MTLBuffer] = []
    for _ in 0 ..< kMaxInflightBuffers {
      guard let dynamicDataBuffer = device.makeBuffer(length: length, options: [.storageModeShared])
      else {
        fatalError("Failed to create buffer")
      }
      mutableDynamicDataBuffers.append(dynamicDataBuffer)
    }
    dynamicDataBuffers = mutableDynamicDataBuffers

    currentFrameIndex = 0

    // debug buffer
//    guard let debugBuffer = device.makeBuffer(
//      length: MemoryLayout<ParticleDebug>.stride * particleCount,
//      options: [.storageModeShared])
//    else {
//      fatalError("Failed to create debug buffer")
//    }
//    self.debugBuffer = debugBuffer

    makeParticlesGPU()
  }
}

extension ParticleRendererMetalPositoin {
  func makeParticles() {
    let pointer = dynamicDataBuffers[0].contents().bindMemory(to: Particle.self,
                                                              capacity: particleCount)

    for i in 0 ..< particleCount {
      pointer[i] = Particle()

      pointer[i].position = SIMD2<Float>(Float.random(in: -1...1),
                                         Float.random(in: -1...1))
      pointer[i].velocity = SIMD2<Float>(Float.random(in: -0.01...0.01),
                                         Float.random(in: -0.01...0.01))

      pointer[i].color = SIMD4<Float>(Float.random(in: 0...0),
                                      Float.random(in: 0...0),
                                      Float.random(in: 0.5...1),
                                      1)

//      print("Particle[\(i)]: \(pointer[i].position) \(pointer[i].velocity) \(pointer[i].color)")
    }
  }

  func makeParticlesGPU() {
    computeSemaphore.wait()

    // Pass in the parameter data.
    let currentBuffer = dynamicDataBuffers[0]

    // Create a new command buffer for each render pass to the current drawable.
    guard let computeCommandBuffer = commandQueue.makeCommandBuffer() else { return }
    computeCommandBuffer.label = "makeParticleCommand"

    let computeEncoder = computeCommandBuffer.makeComputeCommandEncoder()!
    computeEncoder.setComputePipelineState(makeParticlePipelineState)
    computeEncoder.setBuffer(currentBuffer, offset: 0, index: 0)

    //  乱数SEEDを作成する、現在の時刻の少数以下部分を利用する
    var randSeed = uint(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1) * 1000000)
//    var randSeed:uint = uint(Date().timeIntervalSince1970)
//    randSeed = 100
    print("randSeed \(randSeed)")
//    randSeed = uint(particleCount)
    computeEncoder.setBuffer(currentBuffer, offset: 0, index: 0)
    computeEncoder.setBytes(&randSeed, length: MemoryLayout<uint>.stride, index: 1)
//    computeEncoder.setBuffer(debugBuffer, offset: 0, index: 2)

    // SIMD幅（Thread数）
    let threadNum = makeParticlePipelineState.threadExecutionWidth

    computeEncoder.dispatchThreadgroups(
      MTLSize(width: (particleCount + threadNum - 1) / threadNum,
              height: 1,
              depth: 1),
      threadsPerThreadgroup: MTLSize(width: threadNum, height: 1, depth: 1))

    computeEncoder.endEncoding()

    computeCommandBuffer.commit()
    computeCommandBuffer.waitUntilCompleted()

//    let debugPtr = debugBuffer.contents().bindMemory(to: ParticleDebug.self, capacity: particleCount)
//    for i in 0 ..< particleCount {
//      print("[\(i)]: index=\(debugPtr[i].index) states=\(debugPtr[i].states) rand1=\(debugPtr[i].rand1) rand2=\(debugPtr[i].rand2) rand3=\(debugPtr[i].rand3) rand4=\(debugPtr[i].rand4) rand5=\(debugPtr[i].rand5) rand6=\(debugPtr[i].rand6)")
//    }

//    let pointer = dynamicDataBuffers[0].contents().bindMemory(to: Particle.self,
//                                                              capacity: particleCount)
//
//    for i in 0 ..< particleCount {
//
//      print("Particle[\(i)]: \(pointer[i].position) \(pointer[i].velocity) \(pointer[i].color)")
//    }

//    var i = 0
//    print("Particle[\(i)]: p\(pointer[i].position) v\(pointer[i].velocity) c\(pointer[i].color)")
//
    computeSemaphore.signal()
  }
}

extension ParticleRendererMetalPositoin: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    print("ParticleRenderer drawableSizeWillChange \(size) currentFrameIndex=\(currentFrameIndex)")
    viewportSize = size
  }

  private func frameUpdate() {
    computeSemaphore.wait()

    // Pass in the parameter data.
    let currentBuffer = dynamicDataBuffers[currentFrameIndex]
    // 次のバッファを更新する
    currentFrameIndex = (currentFrameIndex + 1) % kMaxInflightBuffers
    let nextBuffer = dynamicDataBuffers[currentFrameIndex]

//    var vSize = vector_float2(Float(viewportSize.width) / 1.0,
//                              Float(viewportSize.height) / 1.0)

    // Create a new command buffer for each render pass to the current drawable.
    guard let computeCommandBuffer = commandQueue.makeCommandBuffer() else { return }
    computeCommandBuffer.label = "MyCommand"

    let computeEncoder = computeCommandBuffer.makeComputeCommandEncoder()!
    computeEncoder.setComputePipelineState(computeParticlePipelineState)
    computeEncoder.setBuffer(currentBuffer, offset: 0, index: 0)
    computeEncoder.setBuffer(nextBuffer, offset: 0, index: 1)

    // SIMD幅（Thread数）
    let threadNum = computeParticlePipelineState.threadExecutionWidth

    computeEncoder.dispatchThreadgroups(
      MTLSize(width: (particleCount + threadNum - 1) / threadNum,
              height: 1,
              depth: 1),
      threadsPerThreadgroup: MTLSize(width: threadNum, height: 1, depth: 1))
    computeEncoder.endEncoding()

    computeCommandBuffer.commit()
    computeCommandBuffer.waitUntilCompleted()

//    let pointer = nextBuffer.contents().bindMemory(to: Particle.self,
//                                                              capacity: particleCount)
//    for i in 0 ..< particleCount {
//
//      print("Particle[\(i)]: \(pointer[i].position) \(pointer[i].velocity) \(pointer[i].color)")
//    }

//    for i in 0 ..< particleCount {
//
//      print("Particle[\(i)]: \(pointer[i].position) \(pointer[i].velocity) \(pointer[i].color)")
//    }

//    var i = 0
//    print("Particle[\(i)]: p\(pointer[i].position) v\(pointer[i].velocity) c\(pointer[i].color)")

    computeSemaphore.signal()
  }

  private func calculateFPS() {
    guard let startTime = startTime else {
      startTime = CACurrentMediaTime()
      return
    }

    frameCount += 1
    let endTime = CACurrentMediaTime()
    let elapsedTime = endTime - startTime

    if elapsedTime >= 1.0 {
      let fps = Double(frameCount) / elapsedTime
      delegate?.renderer(self, didUpdateFPS: fps)
      self.startTime = endTime
      self.frameCount = 0
    }
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

    var fParticleSize = Float(particleSize)

    // slow function emulate
//    usleep(1_000_000 * 5 )
    frameUpdate()

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

//    // Pass in the parameter data.
//    let pointer = currentBuffer.contents().bindMemory(to: Particle.self,
//                                                              capacity: particleCount)
//    for i in 0 ..< particleCount {
//
//      print("Particle[\(i)]: \(pointer[i].position) \(pointer[i].velocity) \(pointer[i].color)")
//    }
    renderEncoder.setVertexBuffer(currentBuffer, offset: 0, index: 0)

//
//    renderEncoder.setVertexBytes(triangleVertices, length: MemoryLayout<AAPLVertex>.stride * triangleVertices.count, index: Int(AAPLVertexInputIndexVertices.rawValue))

//    print("viewportSize \(viewportSize)")

    renderEncoder.setVertexBytes(&vSize, length: MemoryLayout<vector_float2>.stride, index: 1)

    renderEncoder.setVertexBytes(&fParticleSize, length: MemoryLayout<Float>.stride, index: 2)

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

    calculateFPS()
  }
}
