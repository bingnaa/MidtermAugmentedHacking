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
    var aimAnchor: AnchorEntity!
    var setupAim: Bool = false
    
    var sphere: SphereEntity!
    var manager = MotionManager()

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
        setupSubscriptions()
    }
        
    func setupScene() {
        // Setup world tracking and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        configuration.environmentTexturing = .automatic
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]
        arView.session.run(configuration)
        
        // DEBUG
        arView.environment.sceneUnderstanding.options.insert(.physics)
        arView.debugOptions.insert(.showSceneUnderstanding)
    }

    func setupSubscriptions() {
        // Process UI signals.
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }
        .store(in: &subscriptions)
        
        scene.subscribe(to: SceneEvents.Update.self) { event in
            // Call renderLoop method on every frame.
            self.renderTime()
        }.store(in: &subscriptions)
        
        arView.scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
            guard let self else { return }
            
            // If entity with name obstacle1 collides with anything.
            if event.entityA.name == "A" || event.entityB.name == "P" {
                print("collision")
                //print(manager.deviceMotion?.attitude.pitch)
                if let pitch = manager.deviceMotion?.attitude.pitch, pitch > 0.6 {
                    print("action")
                    triggerEntity(ent: event.entityB)
                }
            }
        }.store(in: &subscriptions)
    }
    
    func processUISignal(_ signal: ViewModel.UISignal) {
        switch signal {
        case .reset:
            resetScene()
        case .spawnParasite:
            instantiateParasitesPool(count: 20)
        }
    }


    // Define entities here.
    func setupEntities() {

        //sphere = SphereEntity(name: "sphere", radius: 0.1, imageName: "checker.png")
        
        let materialBox = SimpleMaterial(color: .white, isMetallic: false)
        let shapeBox = MeshResource.generateBox(width: 0.5, height: 0.5, depth: 10)
        let shapeBoxEntity = ModelEntity(mesh: shapeBox, materials: [materialBox])
        shapeBoxEntity.name = "A"
        //shapeBoxEntity.collision = CollisionComponent(shapes: [.generateBox(width: 0.1, height: 0.1, depth: 1)])
        shapeBoxEntity.generateCollisionShapes(recursive: true)
        
        //shapeBoxEntity.physicsBody = PhysicsBodyComponent(shapes: [.generateBox(width: 0.1, height: 0.1, depth: 1)], mass: 3)
        shapeBoxEntity.physicsBody?.mode = .static
        
        let boxAim = AimEntity(modelEntity: shapeBoxEntity, name: "A")
        if let currentFrame = arView.session.currentFrame {
            aimAnchor = AnchorEntity(world: currentFrame.camera.transform)
            aimAnchor.addChild(boxAim)
            arView.scene.addAnchor(aimAnchor)
            setupAim = true
        } else {
            print("currentFrame is nil")
        }

        //debug
//        if let aim = aim {
//            let boxAim = AimEntity(modelEntity: shapeBoxEntity)
//            aim.addChild(boxAim)
//            arView.scene.addAnchor(aim)
//        } else {
//            print("broken")
//        }
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
    
    func renderTime(){
        if let currentFrame = arView.session.currentFrame, setupAim {
            // Get the camera's transform.
            let cameraTransform = currentFrame.camera.transform

            // Define the distance from the camera to the virtual plane.
            let distanceToPlane: Float = 0.1  // Adjust as needed.

            // Calculate a point on the virtual plane based on the camera's translation.
            let planePosition = cameraTransform.translation + cameraTransform.columns.1.xyz * distanceToPlane

            // Set the rectangle face's translation to the calculated position.
            aimAnchor.transform.translation = planePosition

            // Calculate the orientation for the rectangle face.
            // Use the camera's rotation and ensure the face's normal aligns with the plane's normal.
            let planeNormal = cameraTransform.columns.2.xyz
            let faceNormal = -planeNormal  // Make the face point outward
            let faceOrientation = simd_quatf(from: faceNormal, to: planeNormal)

            // Set the rectangle face's rotation to the calculated orientation.
            aimAnchor.transform.rotation = faceOrientation

                // Uncomment these lines to debug the position and rotation.
                //print("Camera Position: \(cameraTransform.translation)")
                //print("Rectangle Position: \(rectangleEntity.transform.translation)")
                //print("Rectangle Rotation: \(rectangleEntity.transform.rotation)")
        }
        else{
            //print("currentFrame is nil")
        }
    }
    
    // Function to spawn an object close to the AR camera.
//    func spawnObjectNearCamera() {
//        if var cameraTransform = arView.session.currentFrame?.camera.transform {
//            print("spawn")
//            // Create a translation matrix to represent the desired forward distance (e.g., 1 meter).
//            let forwardDistance: Float = 0.01 // You can adjust this value as needed.
//            let translationMatrix = simd_float4x4(float4([1, 0, 0, 0]),
//                                                float4([0, 1, 0, 0]),
//                                                float4([0, 0, 1, forwardDistance]),
//                                                float4([0, 0, 0, 1]))
//                
//            // Multiply the camera transform by the translation matrix to move the camera forward.
//            cameraTransform = simd_mul(cameraTransform, translationMatrix)
//            
//            // Extract the position from the updated camera transform.
//            let position = simd_make_float3(cameraTransform.columns.3)
//                
//            // Now, 'position' represents the point 1 meter in front of the camera.
//                
//            // Create and add your AR object at this position.
//            // Create a mesh for the ModelEntity (e.g., a sphere)
//            let mesh = MeshResource.generateSphere(radius: 0.1)
//
//            // Create a material for the ModelEntity (e.g., a red color)
//            let material = SimpleMaterial(color: .red, isMetallic: false)
//
//            // Create the ModelEntity
//            let mEntity = ModelEntity(mesh: mesh, materials: [material])
//                
//            let arObject = Parasites(modelEntity: mEntity, active: true, cameraView: self)
//            //let arObject = SphereEntity(name: "sphere", radius: 0.1, imageName: "checker.png")
//            arObject.position = position
//                
//            // Add the object to the AR scene.
//            let objectAnchor = AnchorEntity(world: position)
//            objectAnchor.addChild(arObject)
//            arView.scene.addAnchor(objectAnchor)
//        }
//    }
    
    func instantiateParasitesPool(count: Int) {
        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            setupEntities()
            
            // Create a mesh for the ModelEntity (e.g., a sphere)
            let mesh = MeshResource.generateSphere(radius: 0.04)

            // Create a material for the ModelEntity (e.g., a red color)
            var material = SimpleMaterial(color: .white, isMetallic: false)
            
            material.color = .init(tint: .white.withAlphaComponent(0.999),
                                   texture: .init(try! .load(named: "beeTexture")))
            
            let radius: Float = 0.05
            let mass: Float   = 5.0

            for _ in 0..<count {
                // Create a translation matrix to represent the desired forward distance (e.g., 1 meter).
                let forwardDistance: Float = 0.01 // You can adjust this value as needed.
                let translationMatrix = simd_float4x4(float4([1, 0, 0, 0]),
                                                       float4([0, 1, 0, 0]),
                                                       float4([0, 0, 1, forwardDistance]),
                                                       float4([0, 0, 0, 1]))

                // Multiply the camera transform by the translation matrix to move the camera forward.
                let transformedCamera = simd_mul(cameraTransform, translationMatrix)

                // Extract the position from the updated camera transform.
                let position = simd_make_float3(transformedCamera.columns.3)

                // Create a new Parasite entity
                let meshEntity = ModelEntity(mesh: mesh, materials: [material])
                meshEntity.name = "P"
                //meshEntity.collision = CollisionComponent(shapes: [.generateSphere(radius: radius)])
                meshEntity.generateCollisionShapes(recursive: true)
                meshEntity.physicsBody = PhysicsBodyComponent(shapes: [.generateSphere(radius: radius)], mass: mass)
                meshEntity.physicsBody?.mode = .static

                let newParasite = Parasites(modelEntity: meshEntity, status: true, cameraView: arView, name: "P")
                                
                newParasite.position = position
                let randomRotationAngle = Float.random(in: 0...2 * .pi)
                newParasite.transform.rotation = simd_quatf(angle: randomRotationAngle, axis: [0, 1, 0])

                // Add the Parasite entity to the AR scene
                let parasiteAnchor = AnchorEntity(world: transformedCamera)
                parasiteAnchor.addChild(newParasite)
                arView.scene.addAnchor(parasiteAnchor)
            }
        }
    }

    func getAvailableParasite() -> Parasites? {
        for entity in scene.anchors.compactMap({ $0 as? Parasites }) {
            if !entity.active {
                entity.active = true
                return entity
            }
        }
        return nil
    }
    
    func triggerEntity(ent: Entity) {
        print(ent.name)
        if let myPara = ent as? Parasites {
            print("dupe")
            myPara.changeState(state: false)
        } else {
            print("Cast failed")
        }
    }
}
