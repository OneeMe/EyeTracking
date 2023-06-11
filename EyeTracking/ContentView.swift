//
//  ContentView.swift
//  EyeTracking
//
//  Created by 我就是御姐我摊牌了 on 2023/6/12.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    @StateObject var lookAtPointData = LookAtPointData()
    
    var body: some View {
        ZStack {
            ARViewContainer(lookAtPointData: lookAtPointData).edgesIgnoringSafeArea(.all)
            GeometryReader { geo in
                Circle()
                    .fill(.red)
                    .position(lookAtPointData.point ?? .zero)
                    .frame(width: 20, height: 20)
                    .fixedSize()
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    @ObservedObject var lookAtPointData: LookAtPointData
    
    func makeUIView(context: Context) -> ARView {
        
        let config = ARFaceTrackingConfiguration()
        config.worldAlignment = .camera
        
        #if targetEnvironment(simulator)
        let arView = ARView(frame: .zero)
        #else
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.session.run(config, options: [.removeExistingAnchors])
        arView.session.delegate = context.coordinator
        #endif
        
        context.coordinator.view = arView
        context.coordinator.lookAtPointData = lookAtPointData
        
        return arView
    }
    
    func makeCoordinator() -> FaceCoordinator {
        return FaceCoordinator()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // update
    }
    
}

class FaceCoordinator: NSObject, ARSessionDelegate {
    weak var view: ARView!
    weak var lookAtPointData: LookAtPointData!
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first(where: { $0 is ARFaceAnchor }) as? ARFaceAnchor else { return }
        
        let facePosition = simd_float3(
            faceAnchor.transform.columns.3.x,
            faceAnchor.transform.columns.3.y,
            faceAnchor.transform.columns.3.z
        )
        
        let lookAtPointInWorld = facePosition + faceAnchor.lookAtPoint
        let lookAtPointInView = view.project(lookAtPointInWorld)
        
        lookAtPointData.point = lookAtPointInView
    }
}

class LookAtPointData: ObservableObject {
    @Published var point: CGPoint?
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
