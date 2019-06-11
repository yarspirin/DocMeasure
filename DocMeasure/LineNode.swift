//
//  LineNode.swift
//  DocMeasure
//
//  Created by Yaroslav on 4/26/19.
//  Copyright © 2019 Mountain Viewer. All rights reserved.
//

import ARKit

class LineNode: SCNNode {
    
    init(from vectorA: SCNVector3, to vectorB: SCNVector3, lineColor color: UIColor, unidirectional: Bool) {
        super.init()
        
        let height = self.distance(from: vectorA, to: vectorB)
        
        self.position = vectorA
        let nodeVector2 = SCNNode()
        nodeVector2.position = vectorB
        
        let nodeZAlign = SCNNode()
        nodeZAlign.eulerAngles.x = Float.pi/2
        
        let box = SCNBox(width: 0.001, height: height, length: 0.001, chamferRadius: 0.0005)
        let material = SCNMaterial()
        material.diffuse.contents = color
        box.materials = [material]
        
        let nodeLine = SCNNode(geometry: box)
        nodeLine.position.y = Float(-height/2) + 0.001
        
        let sphere = SCNSphere(radius: 0.003)
        sphere.materials = [material]

        let startSphereNode = SCNNode(geometry: sphere)
        startSphereNode.position.y = 0.001
        nodeZAlign.addChildNode(startSphereNode)

        if !unidirectional {
            let endSphereNode = SCNNode(geometry: sphere)
            endSphereNode.position.y = -Float(height) + 0.001
            nodeZAlign.addChildNode(endSphereNode)
        }
        
        nodeZAlign.addChildNode(nodeLine)
        self.addChildNode(nodeZAlign)
        
        self.constraints = [SCNLookAtConstraint(target: nodeVector2)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func distance(from vectorA: SCNVector3, to vectorB: SCNVector3)-> CGFloat {
        return CGFloat (sqrt(
            (vectorA.x - vectorB.x) * (vectorA.x - vectorB.x)
                +   (vectorA.y - vectorB.y) * (vectorA.y - vectorB.y)
                +   (vectorA.z - vectorB.z) * (vectorA.z - vectorB.z)))
    }
    
}
