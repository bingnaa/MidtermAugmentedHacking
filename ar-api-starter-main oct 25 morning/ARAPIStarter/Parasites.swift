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
    private var targetPosition: SIMD3<Float>?

    var active: Bool = true {
        didSet {
            // physics
            if active {
                //self.model?.isEnabled = true
                self.model?.physicsBody?.mode = .static
                moveToRandomPosition()
            } else {
                //self.model?.isEnabled = false
                self.model?.physicsBody?.mode = .dynamic
                if let modelWithPhysics = self.model {
                    modelWithPhysics.addForce([0, 500, -1000], relativeTo: self.model)
                }
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

    init(modelEntity: ModelEntity, status: Bool, cameraView: ARView, name: String) {
        super.init()
        self.active = status
        self.model = modelEntity
        self.model?.name = name
        
        if let model = self.model {
            self.addChild(model)
        }

        self.cameraView = cameraView

        // Start a timer to update the position at random intervals
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
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

        // Store the target position
        self.targetPosition = SIMD3(randomX, randomY, randomZ)

        // Start a timer to update the position gradually
        let updateInterval = 0.2  // Adjust the interval as needed
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updatePositionTowardsTarget()
        }
    }

    private func updatePositionTowardsTarget() {
        guard let targetPosition = self.targetPosition else { return }

        // Get the current entity's position
        let currentPosition = self.transform.translation

        // Calculate the direction towards the target position
        let direction = targetPosition - currentPosition

        // Define the speed of movement
        let movementSpeed: Float = 0.1  // Adjust the speed as needed

        // Calculate the length of the direction vector
        let distanceToTarget = length(direction)

        // Ensure the direction vector is not too small to avoid division by zero
        if distanceToTarget < 0.001 {
            return
        }

        // Normalize the direction vector
        let normalizedDirection = direction / distanceToTarget

        // Calculate the new position by moving towards the target
        let newPosition = currentPosition + (normalizedDirection * movementSpeed)

        // Update the entity's position
        self.transform.translation = newPosition

        // Check if the entity has reached the target
        if distanceToTarget < movementSpeed {
            // Stop the timer and clear the target position
            self.timer?.invalidate()
            self.targetPosition = nil
        }
    }
    
    public func changeState(state: Bool){
        active = state
        print("state change")
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
