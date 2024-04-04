/// Users/bj/develop/CopyCleaner/SwiftUIButtonAnim/SwiftUIButtonAnim
// Copyright (c) 2024, - All rights reserved.
//
//

import SwiftUI

struct MetalSampleView: View {
  enum Images: String, CaseIterable, Identifiable {
    case marbles, ball, bird
    var id: Self { self }
  }
  
  @State private var selectedImage: Images = .bird
  @State private var fps: Double = 0.0
  
  @State var particleCount: Int = 10000
  @State var particleSize: Int = 8
  @State var preferredFPS: Int = 60
  
  var particleCountProxy: Binding<Double> {
    Binding<Double>(get: {
      Double(particleCount)
    }, set: {
      
      particleCount = $0 > 0 ? Int($0): 1
    })
  }
  
  
  var particleSizeProxy: Binding<Double> {
    Binding<Double>(get: {
      Double(particleSize)
    }, set: {
      particleSize = Int($0)
    })
  }
  var preferredFPSProxy: Binding<Double> {
    Binding<Double>(get: {
      Double(preferredFPS)
    }, set: {
      preferredFPS = Int($0)
    })
  }
  init() {}
  
  var body: some View {
    VStack {
      ZStack {}
      
      MetalView(fps: $fps,
                particleCount: particleCount,
                particleSize: particleSize,
                preferredFPS: preferredFPS,
                
                
                image: UIImage(imageLiteralResourceName: selectedImage.rawValue))
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: UIColor.systemBackground))
      
      List {
        Section(header: Text("Info")) {
          HStack {
            Text("FPS: ")
            Spacer()
            Text(String(format: "%.2f", fps))
          }
        }
        
        Section(header: Text("setting")) {
//          Picker("Image", selection: $selectedImage) {
//            ForEach(Images.allCases) { images in
//              Text(images.rawValue.capitalized)
//                .tag(images.rawValue.capitalized)
//            }
//          }
          
          VStack {
            HStack {
              ListLabelText(label: "Num", value: "\(String(format: "%d", particleCount))")
                .frame(width: 120, alignment: .leading)
              Slider(value: particleCountProxy, in: 0.0 ... 500000.0, step: 1000.0)
            }
          }
          .padding(0)
          .listRowSeparator(.visible, edges: .all)
          
          VStack {
            HStack {
              ListLabelText(label: "Size", value: "\(String(format: "%d", particleSize))")
                .frame(width: 100, alignment: .leading)
              Slider(value: particleSizeProxy, in: 1.0 ... 100, step: 1.0)
            }
          }
          .padding(0)
          .listRowSeparator(.visible, edges: .all)
          VStack {
            HStack {
              ListLabelText(label: "FPS", value: "\(String(format: "%d", preferredFPS))")
                .frame(width: 100, alignment: .leading)
              Slider(value: preferredFPSProxy, in: 1.0 ... 120, step: 1.0)
            }
          }
          .padding(0)
          .listRowSeparator(.visible, edges: .all)

        }
      }
    }
  }
}

#Preview {
  MetalSampleView()
}
