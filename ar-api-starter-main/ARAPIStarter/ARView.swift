//
//  ARView.swift
//  ARAPIStarter
//
//  Created by Nien Lam on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import SwiftUI
import ARKit
import RealityKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    let viewModel: ViewModel
    var manager = MotionManager()
    
    func makeUIView(context: Context) -> SimpleARView {
        SimpleARView(frame: .zero, viewModel: viewModel)
    }
    
    func updateUIView(_ arView: SimpleARView, context: Context) { }
}

class SimpleARView: ARView {
    var viewModel: ViewModel
    var arView: ARView { return self }
    var subscriptions = Set<AnyCancellable>()
    
    var spawnedObject: AnchorEntity?
    var planeAnchor: AnchorEntity?
    var originAnchor: AnchorEntity!

    var sphere: SphereEntity!

    init(frame: CGRect, viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupScene()
        setupEntities()
        setupSubscriptions()
    }
        
    func setupScene() {
        // Setup world tracking and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        configuration.environmentTexturing = .automatic
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]
        arView.session.run(configuration)
    }

    func setupSubscriptions() {
        // Process UI signals.
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }
        .store(in: &subscriptions)

        // Observe slider value.
        viewModel.$sliderValue.sink { [weak self] value in
            guard let self else { return }
            
            let scale = value * 2
            sphere.scale = [scale, scale, scale]
        }
        .store(in: &subscriptions)
    }
    
    func processUISignal(_ signal: ViewModel.UISignal) {
        switch signal {
        case .reset:
            resetScene()
        case .spawnParasite:
            spawnObjectNearCamera()
        }
    }


    // Define entities here.
    func setupEntities() {
        //arView.scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0) // Apply Earth-like gravity

        sphere = SphereEntity(name: "sphere", radius: 0.1, imageName: "checker.png")
    }
    

    // Reset plane anchor and position entities.
    func resetScene() {
        // Reset plane anchor. //
        planeAnchor?.removeFromParent()
        planeAnchor = nil
        planeAnchor = AnchorEntity(plane: [.vertical])
        arView.scene.addAnchor(planeAnchor!)
        
        // Position and add sphere to scene.
        sphere.position.x = 0
        sphere.position.y = 0
        sphere.position.z = 0
        planeAnchor?.addChild(sphere)
    }
    
    // Function to spawn an object close to the AR camera.
        func spawnObjectNearCamera() {
            if var cameraTransform = arView.session.currentFrame?.camera.transform {
                print("spawn")
                // Create a translation matrix to represent the desired forward distance (e.g., 1 meter).
                let forwardDistance: Float = 0.01 // You can adjust this value as needed.
                let translationMatrix = simd_float4x4(float4([1, 0, 0, 0]),
                                                       float4([0, 1, 0, 0]),
                                                       float4([0, 0, 1, forwardDistance]),
                                                       float4([0, 0, 0, 1]))
                
                // Multiply the camera transform by the translation matrix to move the camera forward.
                cameraTransform = simd_mul(cameraTransform, translationMatrix)
                
                // Extract the position from the updated camera transform.
                let position = simd_make_float3(cameraTransform.columns.3)
                
                // Now, 'position' represents the point 1 meter in front of the camera.
                
                // Create and add your AR object at this position.
                // Create a mesh for the ModelEntity (e.g., a sphere)
                let mesh = MeshResource.generateSphere(radius: 0.1)

                // Create a material for the ModelEntity (e.g., a red color)
                let material = SimpleMaterial(color: .red, isMetallic: false)

                // Create the ModelEntity
                let mEntity = ModelEntity(mesh: mesh, materials: [material])
                
                let arObject = Parasites(modelEntity: mEntity, active: true, cameraView: self)
                //let arObject = SphereEntity(name: "sphere", radius: 0.1, imageName: "checker.png")
                arObject.position = position
                
                // Add the object to the AR scene.
                let objectAnchor = AnchorEntity(world: position)
                objectAnchor.addChild(arObject)
                arView.scene.addAnchor(objectAnchor)
            }
        }
}
