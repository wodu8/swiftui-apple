//
// Copyright (c) 2024, - All rights reserved.
//
//

import SwiftUI

struct BlendSampleView: View {
  
  enum Images: String, CaseIterable, Identifiable {
    case marbles, ball, bird
    var id: Self { self }
  }
  
  @State private var selectedImage: Images = .ball
  
  init() {}
  
  var body: some View {
    VStack {
      ZStack {}
      
      BlendView(image: UIImage(imageLiteralResourceName: selectedImage.rawValue))
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: UIColor.systemBackground))
      
      List {
        Section(header: Text("Image")) {
          Picker("Image", selection: $selectedImage) {
            ForEach(Images.allCases) { images in
              Text(images.rawValue.capitalized)
                .tag(images.rawValue.capitalized)
            }
          }
        }
      }
    }
  }
}

#Preview {
  BlendSampleView()
}
