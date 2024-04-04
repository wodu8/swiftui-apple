//
// Copyright (c) 2024, - All rights reserved. 
// 
//

import Foundation

// MTKViewのdraw回数からFPSを算出するヘルパクラス
class MTKViewFPSHelper {
  private var lastTimestamp: CFTimeInterval = 0
  private var frameCount: Int = 0
  private var fps: Double = 0
  private var timer: Timer?
  
  init() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
      guard let self = self else { return }
      self.fps = Double(self.frameCount)
      self.frameCount = 0
    }
  }
  
  deinit {
    timer?.invalidate()
  }
  
  func updateFPS(timestamp: CFTimeInterval) -> Double {
    frameCount += 1
    let delta = timestamp - lastTimestamp
    lastTimestamp = timestamp
    return delta > 0 ? 1 / delta : 0
  }
  
  func getFPS() -> Double {
    return fps
  }

  
}
