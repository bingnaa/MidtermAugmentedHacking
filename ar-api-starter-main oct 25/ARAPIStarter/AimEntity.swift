//
//  AimEntity.swift
//  ARAPIStarter
//
//  Created by Briana Jones on 10/24/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import Foundation
import ARKit
import RealityKit

class AimEntity: Entity{
    var model: ModelEntity? {
        didSet {
            if let model = self.model {
                // Set the model entity's initial properties
                model.scale = [1.0, 1.0, 1.0]
            }
        }
    }
    private var timer: Timer?
    
    init(modelEntity: ModelEntity, name: String) {
        super.init()
        self.model = modelEntity
        self.model?.name = name
        
        if let model = self.model {
            self.addChild(model)
        }
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
}
