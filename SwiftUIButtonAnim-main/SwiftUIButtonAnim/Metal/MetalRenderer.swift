//
// Copyright (c) 2024, - All rights reserved.
//
//

import Foundation
import MetalKit


class MetalRenderer: NSObject {
  private var device: MTLDevice
  private var pipelineState: MTLRenderPipelineState!
  private var commandQueue: MTLCommandQueue!
  private var vertexBuffer: MTLBuffer!
  private var uniformBuffer: MTLBuffer!

  private var viewportSize: vector_uint2 = .init(0, 0)

  let triangleVertices: [AAPLVertex] = [
      // 2D positions,    RGBA colors
      AAPLVertex(position: SIMD2<Float>(250, -250), color: SIMD4<Float>(0.5, 0, 0, 1)),
      AAPLVertex(position: SIMD2<Float>(-250, -250), color: SIMD4<Float>(1, 0, 0, 1)),
      AAPLVertex(position: SIMD2<Float>(0, 250), color: SIMD4<Float>(0.5, 0, 0, 0.5))
  ]

  init(metalKitView mtkView: MTKView) {
    print("MetalRenderer init")
    if mtkView.device == nil {
      fatalError("Device not created. Run on a physical device")
    }

    self.device = mtkView.device!
    super.init()

    guard let library = device.makeDefaultLibrary() else {
      fatalError("Failed to create library")
    }

    guard let vertexFunction = library.makeFunction(name: "vertexShader") else {
      fatalError("Failed to create vertex function")
    }
    guard let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
      fatalError("Failed to create fragment function")
    }

    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "Simple Pipeline"
    pipelineStateDescriptor.vertexFunction = vertexFunction
    pipelineStateDescriptor.fragmentFunction = fragmentFunction
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

    do {
      pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      fatalError("Failed to create pipeline state")
    }

    commandQueue = device.makeCommandQueue()
    print("MetalRenderer init finish")
  }

//    private func createPipelineState(){
//      let library = device.makeDefaultLibrary()
//      let vertexFunction = library?.makeFunction(name: "vertex_main")
//      let fragmentFunction = library?.makeFunction(name: "fragment_main")
//
//      let pipelineDescriptor = MTLRenderPipelineDescriptor()
//      pipelineDescriptor.vertexFunction = vertexFunction
//      pipelineDescriptor.fragmentFunction = fragmentFunction
//      pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
//
//      do {
//        pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
//      } catch {
//        fatalError("Failed to create pipeline state")
//      }
//    }

//
//    private func createBuffers(){
//      let vertexData: [Float] = [
//        -1, -1, 0, 1,
//        1, -1, 0, 1,
//        -1, 1, 0, 1,
//        1, 1, 0, 1
//      ]
//
//      vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
//
//      let uniformData: [Float] = [
//        1, 0, 0, 0
//      ]
//
//      uniformBuffer = device.makeBuffer(bytes: uniformData, length: uniformData.count * MemoryLayout<Float>.size, options: [])
//    }
//
//    func render(view: MTKView){
//      guard let commandBuffer = commandQueue.makeCommandBuffer(),
//            let descriptor = view.currentRenderPassDescriptor,
//            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
//        return
//      }
//
//      renderEncoder.setRenderPipelineState(pipelineState)
//      renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//      renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
//      renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
//      renderEncoder.endEncoding()
//
//      commandBuffer.present(view.currentDrawable!)
//      commandBuffer.commit()
//    }
//
}

extension MetalRenderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    print("MetalRenderer drawableSizeWillChange \(size) ")

    viewportSize = vector_uint2(UInt32(size.width), UInt32(size.height))
  }

  func draw(in view: MTKView) {
    print("MetalRenderer draw ")
    
    // Create a new command buffer for each render pass to the current drawable.
    guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
    commandBuffer.label = "MyCommand"

    // Obtain a renderPassDescriptor generated from the view's drawable textures.
    guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

    // Create a render command encoder.
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
    renderEncoder.label = "MyRenderEncoder"

    // Set the region of the drawable to draw into.
    renderEncoder.setViewport(
      MTLViewport(originX: 0.0, 
                  originY: 0.0,
                  width: Double(viewportSize.x),
                  height: Double(viewportSize.y),
                  znear: 0.0, zfar: 1.0))

    renderEncoder.setRenderPipelineState(pipelineState)

    // Pass in the parameter data.
    renderEncoder.setVertexBytes(triangleVertices, length: MemoryLayout<AAPLVertex>.stride * triangleVertices.count, index: Int(AAPLVertexInputIndexVertices.rawValue))

    var viewportSize = viewportSize
    renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<CGSize>.stride, index: Int(AAPLVertexInputIndexViewportSize.rawValue))

    // Draw the triangle.
    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

    renderEncoder.endEncoding()

    // Schedule a present once the framebuffer is complete using the current drawable.
    commandBuffer.present(view.currentDrawable!)

    // Finalize rendering here & push the command buffer to the GPU.
    commandBuffer.commit()
    
    
  }

}
