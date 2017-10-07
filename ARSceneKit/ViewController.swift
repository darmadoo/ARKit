//
//  ViewController.swift
//  ARSceneKit
//
//  Created by Joshua Homann on 7/17/17.
//  Copyright © 2017 Joshua Homann. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

/*
 TODO:
 0) Change the eueler scale for the pudge model so that it faces you all the time
 1) Create UI on bottom bar with multiple models to pick from, placing that selected model on the screen on click
   a) Download multiple models from https://free3d.com/3d-models/all/1/dae
 2) Make a logo for the app, rename app as well
 3) Rewrite algorithm so that we clear object if we click on it.
 4) Drag and drop objects capabilities.
 5) *** Ability to detect depth of field using camera ***
 6) Ability to press and rotate using two fingers
 7) Clear all capabilities (Clear all models on the view)
    a) Lock/Unlock functionality (Lock objects that cannot be cleared)
       i) Change model (?)
 8) Menu UI
    a) Take a screenshot
    b) Account settings
    c) Version #
 9) Inventorized objects so that we can reuse objects for other clients (IKEA JENNYLUND chair, etc...)
 10) Measuring tape side functionality to be able to measure room
 */


class ARViewController: UIViewController {
    // MARK: - IBOutlet
    @IBOutlet weak var sceneView: ARSCNView! {
        didSet {
            sceneView.scene = SCNScene()
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            sceneView.showsStatistics = true
            sceneView.autoenablesDefaultLighting = false
            sceneView.antialiasingMode = .multisampling4X
            
        }
    }

    private func plane(from anchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = UIColor.green.withAlphaComponent(0.25)
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        
        node.position = .init(anchor.center.x, 0 , anchor.center.z)
        node.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        //node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: plane, options: [:]))
        return node
    }
    
    private func makeSphere( with transform : matrix_float4x4) -> SCNNode {
        let sphere = SCNSphere(radius : 0.01)
        let node = SCNNode(geometry: sphere)
        node.transform = SCNMatrix4MakeTranslation(transform.columns.3.x, transform.columns.3.y + 0.5, transform.columns.3.z)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: sphere, options: [:]))
        return node
        
    }
    
    
    private var planes: Set<SCNNode> = []
    private lazy var earthNode: SCNNode = {
        let scene = SCNScene(named: "art.scnassets/pudge/pudge.dae")
        let wrapper = SCNNode()
        scene?.rootNode.childNodes.forEach { wrapper.addChildNode($0) }
    
    wrapper.scale = .init(0.25, 0.25, 0.25)
    wrapper.position = .init(0, 0.1, 0)
    return wrapper
}()
    
    private lazy var earthNodes: Set<SCNNode> = {
        var set: Set<SCNNode> = []
        self.earthNode.enumerateChildNodes { node, _ in set.insert(node) }
        return set
    }()
    
    private var isAnimating: Bool = false {
        didSet {
            earthNodes.forEach { $0.removeAllAnimations() }
            if isAnimating {
                let day = self.createSpinAnimation(duration: 1)
                let moon = self.createSpinAnimation(duration: 28)
                earthNode.childNode(withName: "earth", recursively: true)?.addAnimation(day, forKey: nil)
                earthNode.childNode(withName: "moon", recursively: true)?.addAnimation(moon, forKey: nil)
                
            }
        }
    }
    

    private func createSpinAnimation(duration: TimeInterval) -> CABasicAnimation {
        
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
        spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float( Float.pi * 2)))
        spin.duration = duration
        spin.repeatCount = .infinity
        return spin
        
    }
    
    
    private var userNodes: [ARAnchor: SCNNode] = [:]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        sceneView.session.pause()
    }
    
    
    // MARK: - IBAction
    @IBAction func tap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        let normalizedPoint = CGPoint(x: location.x / sceneView.bounds.size.width, y: location.y / sceneView.bounds.size.height)
        let results = sceneView.session.currentFrame?.hitTest(normalizedPoint  , types: [.estimatedHorizontalPlane, .existingPlane, .featurePoint])
        
        guard let closes = results?.first else {
            return
        }
        
        let transform = closes.worldTransform
        sceneView.scene.rootNode.addChildNode(makeSphere(with: transform))
        
        let anchor = ARAnchor(transform: transform)
        sceneView.session.add(anchor: anchor)
        userNodes[anchor] = earthNode
        
        
    }

    // Can be used to resize object but does not make sense for this project.
    @IBAction func pinch(_ recognizer: UIPinchGestureRecognizer) {

    }

    @IBAction func pan(_ recognizer: UIPanGestureRecognizer) {

    }
}

extension ARViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {
                let modelClone = self.earthNode.clone()
                modelClone.position = SCNVector3Zero
                
                node.addChildNode(modelClone)
                
            }
            
            
        }
        /*
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeNode = plane(from: planeAnchor)
            node.addChildNode(planeNode)
        }
 */
        
    }
    



}
