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
        let scene = SCNScene(named: "art.scnassets/earth.scn")
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
