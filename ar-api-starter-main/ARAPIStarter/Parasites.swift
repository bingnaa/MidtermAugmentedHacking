//
//  Parasites.swift
//  ARAPIStarter
//
//  Created by Briana Jones on 10/23/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import Foundation
import ARKit
import RealityKit

class Parasites: Entity {
    private var timer: Timer?
    private var cameraView: ARView?

    var active: Bool = true {
        didSet {
            // Handle the behavior when the 'active' state changes
            if active {
                // Activate the enemy (e.g., show, enable AI behavior, etc.)
                self.model?.isEnabled = true
            } else {
                // Deactivate the enemy (e.g., hide, disable AI behavior, etc.)
                self.model?.isEnabled = false
            }
        }
    }

    var model: ModelEntity? {
        didSet {
            if let model = self.model {
                // Set the model entity's initial properties
                model.scale = [1.0, 1.0, 1.0]
                model.generateCollisionShapes(recursive: true)
                model.isEnabled = active // Enable the model if 'active' is true
            }
        }
    }

    init(modelEntity: ModelEntity, active: Bool, cameraView: ARView) {
        super.init()
        self.active = active
        self.model = modelEntity
        if let model = self.model {
            self.addChild(model)
        }

        self.cameraView = cameraView

        // Start a timer to update the position at random intervals
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.moveToRandomPosition()
        }
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    private func moveToRandomPosition() {
        guard let cameraView = self.cameraView,
        let camera = cameraView.session.currentFrame?.camera else { return }


        // Generate random positions within the boundaries of the camera view
        let randomX = Float.random(in: -1.0...1.0)
        let randomY = Float.random(in: -1.0...1.0)
        let randomZ = Float.random(in: -1.0...1.0)

        // Set the entity's position relative to the camera
        // Set the entity's position relative to the camera
        let cameraTransform = camera.transform
        var translationMatrix = float4x4(diagonal: [1, 1, 1, 1])
        translationMatrix.columns.3.x = randomX
        translationMatrix.columns.3.y = randomY
        translationMatrix.columns.3.z = randomZ
        let newPosition = cameraTransform * translationMatrix
        self.transform.matrix = newPosition
    }
}


//class Parasites: SCNNode {
//    //var model: ModelEntity
//    var active: Bool = true {
//        didSet {
//            if active {
//
//            } else {
//                physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: self, options: nil))
//                // Set up other physics properties like mass, friction, etc. as needed
//                physicsBody?.mass = 0.5
//                physicsBody?.friction = 0.5
//            }
//        }
//    }
////    var modelNode: SCNNode? {
////        didSet {
////            if active {
////                if let modelNode = self.modelNode {
////                    self.geometry = modelNode.geometry
////                }
////            }
////        }
////    }
//
//    init(geometry: SCNGeometry) {
//        super.init()
//        self.geometry = geometry
//        // Initially set the object as active
//        active = true
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//}
