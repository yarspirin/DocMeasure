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
    
    // Outlets
    
    @IBOutlet weak var applyButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var planeAdviceView: UIVisualEffectView!
    @IBOutlet weak var cornerAdviceView: UIVisualEffectView!
    
    @IBOutlet weak var aimView: UIView!
    
    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var unitButton: UIButton!
    
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var binButton: UIButton!
    
    // Variables
    
    let kInchPerCm: Double = 0.3937007874
    let kCmPerInch: Double = 2.54
    
    enum Unit {
        case inch
        case centimeter
    }
    
    var unit: Unit = .centimeter
    var width: Double?
    var height: Double?
    
    enum State {
        case notMeasuring
        case measuringFirstSide
        case measuringSecondSide
    }
    
    var lineNode: LineNode?
    var measurements: [LineNode] = []
    var state: State = .notMeasuring
    
    let session = ARSession()
    let sessionConfig: ARConfiguration = ARWorldTrackingConfiguration()
    
    var startValue = SCNVector3()
    var endValue = SCNVector3()
    
    // UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupViews()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    // Setups
    
    func updateMeasureElements(hide: Bool) {
        if hide {
            planeAdviceView.isHidden = false
            cornerAdviceView.isHidden = true
            aimView.isHidden = true
            widthLabel.isHidden = true
            heightLabel.isHidden = true
            unitButton.isHidden = true
            plusButton.isHidden = true
            binButton.isHidden = true
        } else {
            planeAdviceView.isHidden = true
            cornerAdviceView.isHidden = false
            aimView.isHidden = false
            widthLabel.isHidden = false
            heightLabel.isHidden = false
            unitButton.isHidden = false
            plusButton.isHidden = false
            binButton.isHidden = false
        }
    }
    
    func setupViews() {
        planeAdviceView.layer.cornerRadius = 4.0
        cornerAdviceView.layer.cornerRadius = 4.0
        aimView.layer.cornerRadius = aimView.bounds.width / 2.0
        
        updateMeasureElements(hide: true)
        
        applyButton.isEnabled = false
        binButton.isEnabled = false
    }
    
    func setupScene() {
        sceneView.delegate = self
        sceneView.session = session
        
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        
        resetValues()
    }
    
    func resetValues() {
        state = .notMeasuring
        
        startValue = SCNVector3()
        endValue = SCNVector3()
    }
    
    func updateUnitLabel(_ value: Double, isHeight: Bool) {
        let cm = value * 100.0
        let inch = cm * kInchPerCm
        
        if isHeight {
            switch unit {
            case .centimeter:
                height = cm
                
            case .inch:
                height = inch
            }
            
            heightLabel.text = String(format: "Высота: %.1f", height!)
        } else {
            switch unit {
            case .centimeter:
                width = cm
                
            case .inch:
                width = inch
            }
            
            widthLabel.text = String(format: "Ширина: %.1f", width!)
        }
    }
    
    // ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.detectObjects()
        }
    }
    
    func detectObjects() {
        if let worldPos = sceneView.realWorldVector(screenPos: view.center) {
            
            updateMeasureElements(hide: false)
            
            if state == .measuringFirstSide || state == .measuringSecondSide {
                if startValue == SCNVector3() {
                    startValue = worldPos
                }
                
                endValue = worldPos
                
                self.lineNode?.removeFromParentNode()
                self.lineNode = LineNode(from: startValue, to: endValue, lineColor: .white, unidirectional: true)
                sceneView.scene.rootNode.addChildNode(self.lineNode!)
            }
        }
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
    
    // Actions
    
    @IBAction func applyButtonTapped(_ sender: Any) {
        // TODO: Integration code
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        // TODO: Integration code
    }
    
    @IBAction func binButtonTouchUpInside(_ sender: Any) {
        state = .notMeasuring
        binButton.isEnabled = false
        plusButton.isEnabled = true
        applyButton.isEnabled = false
        
        if let lineNode = lineNode {
            lineNode.removeFromParentNode()
        }
        lineNode = nil
        
        for measurement in measurements {
            measurement.removeFromParentNode()
        }
        
        measurements = []
        
        widthLabel.text = "Ширина:"
        heightLabel.text = "Высота:"
        
        width = nil
        height = nil
    }
    
    @IBAction func plusButtonTouchUpInside(_ sender: Any) {
        binButton.isEnabled = true
        
        switch state {
        case .notMeasuring:
            resetValues()
            state = .measuringFirstSide
            
        case .measuringFirstSide:
            let lineNode = LineNode(from: startValue, to: endValue, lineColor: .yellow, unidirectional: true)
            measurements.append(lineNode)
            
            sceneView.scene.rootNode.addChildNode(lineNode)
            
            let distance = startValue.distance(from: endValue)
            updateUnitLabel(Double(distance), isHeight: true)
            
            //addText()
            startValue = endValue
            
            state = .measuringSecondSide
            
        case .measuringSecondSide:
            let lineNode = LineNode(from: startValue, to: endValue, lineColor: .yellow, unidirectional: false)
            measurements.append(lineNode)
            
            self.lineNode?.removeFromParentNode()
            self.lineNode = nil

            sceneView.scene.rootNode.addChildNode(lineNode)
            
            let distance = startValue.distance(from: endValue)
            updateUnitLabel(Double(distance), isHeight: false)
            
            plusButton.isEnabled = false
            applyButton.isEnabled = true
            
            //addText()
            resetValues()
        }
    }
    
    @IBAction func unitButtonTouchUpInside(_ sender: Any) {
        switch unit {
        case .centimeter:
            if let width = self.width {
                self.width = width * kInchPerCm
                widthLabel.text = String(format: "Ширина: %.1f", self.width!)
            }
            
            if let height = self.height {
                self.height = height * kInchPerCm
                heightLabel.text = String(format: "Высота: %.1f", self.height!)
            }
            
            unitButton.setTitle("Дюймы", for: .normal)
            unit = .inch
        case .inch:
            if let width = self.width {
                self.width = width * kCmPerInch
                widthLabel.text = String(format: "Ширина: %.1f", self.width!)
            }
            
            if let height = self.height {
                self.height = height * kCmPerInch
                heightLabel.text = String(format: "Высота: %.1f", self.height!)
            }
            
            unitButton.setTitle("Сантиметры", for: .normal)
            unit = .centimeter
        }
    }
}
