//
//  ViewController.swift
//  DocMeasure
//
//  Created by Yaroslav on 5/31/19.
//  Copyright © 2019 Mountain Viewer. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

final class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var aimLabel: UILabel!
    @IBOutlet weak var notReadyLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    var lineNode: LineNode?
    var measurements: [LineNode] = []
    let session = ARSession()
    let vectorZero = SCNVector3()
    let sessionConfig: ARConfiguration = ARWorldTrackingConfiguration()
    var measuring = false
    var startValue = SCNVector3()
    var endValue = SCNVector3()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    func setupScene() {
        sceneView.delegate = self
        sceneView.session = session
        
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        
        resetValues()
    }
    
    func resetValues() {
        measuring = false
        startValue = SCNVector3()
        endValue =  SCNVector3()
        
        updateResultLabel(0.0)
    }
    
    func updateResultLabel(_ value: Float) {
        let cm = value * 100.0
        let inch = cm * 0.3937007874
        resultLabel.text = String(format: "%.2f cm / %.2f\"", cm, inch)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.detectObjects()
        }
    }
    
    func detectObjects() {
        if let worldPos = sceneView.realWorldVector(screenPos: view.center) {
            aimLabel.isHidden = false
            notReadyLabel.isHidden = true
            if measuring {
                if startValue == vectorZero {
                    startValue = worldPos
                }
                
                endValue = worldPos
                updateResultLabel(startValue.distance(from: endValue))
                
                self.lineNode?.removeFromParentNode()
                self.lineNode = LineNode(from: startValue, to: endValue, lineColor: .yellow)
                sceneView.scene.rootNode.addChildNode(self.lineNode!)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetValues()
        measuring = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        measuring = false
        let lineNode = LineNode(from: startValue, to: endValue, lineColor: .yellow)
        measurements.append(lineNode)
        sceneView.scene.rootNode.addChildNode(lineNode)
        
        addText()
    }
    
    private func addText() {
        let minPosition = startValue
        let maxPosition = endValue
        
        let dx = (maxPosition.x + minPosition.x) / 2.0
        let dy = (maxPosition.y + minPosition.y) / 2.0 + 0.02
        let dz = (maxPosition.z + minPosition.z) / 2.0
        
        let position = SCNVector3(dx, dy, dz)
        let distance = startValue.distance(from: endValue) * 100
        
        let text = String(format: "%.2f cm", distance)
        
        // Create the textNode
        let textNode = TextNode(text)
        
        textNode.color = .black
        textNode.position = position
        
        textNode.font = UIFont(name: "AvenirNext-Bold", size: 0.1)
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
}
