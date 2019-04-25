//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import ARKit
import UIKit
import Vision

open class OsmosisARViewController: UIViewController {
  
  // MARK: - Properties
  
  @IBOutlet public var sceneView: ARSCNView!

  var currentBuffer: CVPixelBuffer?
  
  var ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 1)
  
  var anchorLabels = [UUID: String]()
  private var allNodes = [SCNNode]()
  private var labels: [ARLabel] = []
  private var screenHeight: Double = 0
  private var screenWidth: Double = 0
  private var identifierString = ""
  private var confidence: VNConfidence = 0.0
  private var currentPredictions = [Prediction]()
  private let visionQueue = DispatchQueue(label: "com.osmosisai.OsmosisAir.serialVisionQueue")
  
  private var classificationRequest: VNCoreMLRequest?
  private var currentFrame: ARFrame?
  
  // MARK: - Object Lifecycle
  
  override open func viewDidLoad() {
    super.viewDidLoad()

    sceneView.delegate = self
  }
  
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    do {
      var model: VNCoreMLModel?
      if let c = SessionData.shared.currentClassifier {
        guard let graphURL = c.graphFileURL else {
          fatalError("Can't open CoreML model URL")
        }
        
        guard let m = try? MLModel(contentsOf: graphURL) else {
          fatalError("Can't open CoreML model")
        }
        ssdPostProcessor = SSDPostProcessor(classifier: c)
        model = try VNCoreMLModel(for: m)
      } else {
        model = try VNCoreMLModel(for: coffeeThermal().model)
      }
      
      classificationRequest = VNCoreMLRequest(model: model!, completionHandler: { [weak self] request, error in
        self?.processClassifications(for: request, error: error, frame: self?.currentFrame)
      })
      classificationRequest?.imageCropAndScaleOption = .centerCrop
      classificationRequest?.usesCPUOnly = true
    } catch {
      fatalError("Failed to load Vision ML model: \(error)")
    }
    
    
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    sceneView.session.delegate = self
    sceneView.session.run(configuration)
    
    clearSession()
  }
  
  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    screenWidth = Double(view.frame.width)
    screenHeight = Double(view.frame.height)
  }
  
  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }
  
  
  // MARK: - Public Methods
  
  public class func setup(storyboard: UIStoryboard? = nil) -> OsmosisARViewController {
    
    if let s = storyboard {
      guard let vc = s.instantiateInitialViewController() as? OsmosisARViewController else {
        fatalError("When using a custom storyboard, please set your OsmosisARViewController as the initial view controller.")
      }
      return vc
    }
    
    
    let frameworkBundle = Bundle(for: OsmosisARViewController.self)
    let viewController = UIStoryboard(name: "OsmosisARViewController", bundle: frameworkBundle).instantiateInitialViewController() as! OsmosisARViewController
    return viewController
  }
  
  
  // MARK: - Private Methods
  
  func clearSession() {
    for a in allNodes {
      a.removeFromParentNode()
    }
    allNodes.removeAll()
    
    for l in labels {
      l.node.removeFromParentNode()
    }
    labels.removeAll()
  }
  
  func classifyCurrentImage(frame: ARFrame) {
    let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)    
    let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
    visionQueue.async {
      do {
        defer { self.currentBuffer = nil }
        self.currentFrame = frame
        try requestHandler.perform([self.classificationRequest!])
      } catch {
        print("Error: Vision request failed with error \"\(error)\"")
      }
    }
  }
  
  func processClassifications(for request: VNRequest, error: Error?, frame: ARFrame?) {
    guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
      return
    }
    
    guard results.count == 2 else {
      return
    }
    guard let boxPredictions = results[1].featureValue.multiArrayValue,
      let classPredictions = results[0].featureValue.multiArrayValue else {
        return
    }
    
    currentPredictions = ssdPostProcessor.postprocess(boxPredictions: boxPredictions, classPredictions: classPredictions)
    drawBoxes(predictions: currentPredictions, frame: frame)
  }
  
  func drawBoxes(predictions: [Prediction], frame: ARFrame?) {
    guard let f = frame else { return }
    
    for a in allNodes {
      a.removeFromParentNode()
    }
    
    allNodes.removeAll()
    
    for (_, prediction) in predictions.enumerated() {
      if let _ = self.ssdPostProcessor.classNames {
        let xOffset: Double = currentOrientation() == .landscapeRight || currentOrientation() == .landscapeLeft ? (screenWidth - screenHeight) / 2 : 0
        let yOffset: Double = currentOrientation() == .landscapeRight || currentOrientation() == .landscapeLeft ? 0 : (screenHeight - screenWidth) / 2
        let imgSize = currentOrientation() == .landscapeRight || currentOrientation() == .landscapeLeft ? screenHeight: screenWidth
        
        let rect = prediction.finalPrediction.toCGRect(imgWidth: imgSize, imgHeight: imgSize, xOffset: xOffset, yOffset: yOffset)
        let screenCentre : CGPoint = CGPoint(x: rect.midX, y: rect.midY)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first,
          let classNames = self.ssdPostProcessor.classNames {
          
          let position = SCNVector3(
            closestResult.worldTransform.columns.3.x,
            closestResult.worldTransform.columns.3.y,
            closestResult.worldTransform.columns.3.z)
          
          let name = classNames[prediction.detectedClass]
          
          let results = labels.filter{ $0.name == name && $0.timestamp != f.timestamp }
            .sorted{ $0.node.position.distance(toVector: position) < $1.node.position.distance(toVector: position) }
          
          guard let existentLabel = results.first else {
            let node = SCNNode.init(withText: name, position: position)
            
            DispatchQueue.main.async {
              self.sceneView.scene.rootNode.addChildNode(node)
              node.show()
            }
            let label = ARLabel(name: name, node: node, timestamp: f.timestamp)
            self.labels.append(label)
            return
          }
          
          DispatchQueue.main.async {
            if let displayLabel = results.filter({ !$0.hidden }).first  {
              
              let distance = displayLabel.node.position.distance(toVector: position)
              if(distance >= 0.03 ) {
                displayLabel.node.move(position)
              }
              displayLabel.timestamp = f.timestamp
              
            } else {
              existentLabel.node.position = position
              existentLabel.node.show()
              existentLabel.timestamp = f.timestamp
            }
          }
          
          let ball = SCNSphere(radius: 0.012)

          let podBundle = Bundle(for: self.classForCoder)
          ball.firstMaterial!.diffuse.contents = UIImage(named: "bullet", in: podBundle, compatibleWith: nil)
          
          let ballNode = SCNNode(geometry: ball)
          ballNode.position = position
          allNodes.append(ballNode)
          sceneView.scene.rootNode.addChildNode(ballNode)

        }
      }
    }
  }
  
  func compensatingEXIFOrientation(deviceOrientation:UIDeviceOrientation) -> EXIFOrientation {
    switch deviceOrientation {
    case .landscapeRight:     return .bottomRight
    case .landscapeLeft:      return .topLeft
    case .portrait:           return .rightTop
    case .portraitUpsideDown: return .leftBottom
    case .faceUp:             return .rightTop
    case .faceDown:           return .rightTop
    case _:                   fallthrough
    default:
      print("Called in unrecognized orientation")
      return .rightTop
    }
  }
  
  @objc func deviceDidRotate() {
    screenWidth = Double(view.frame.width)
    screenHeight = Double(view.frame.height)
  }
  
  private func currentOrientation() -> AVCaptureVideoOrientation {
    let currentDevice = UIDevice.current
    
    switch (currentDevice.orientation) {
    case .portrait:             return .portrait
    case .landscapeRight:       return .landscapeLeft
    case .landscapeLeft:        return .landscapeRight
    case .portraitUpsideDown:   return .portraitUpsideDown
    default:                    return .portrait
    }
  }

  private func sigmoid(_ val:Double) -> Double {
    return 1.0/(1.0 + exp(-val))
  }
  

  // MARK: - Action Methods
  
  @IBAction func placeLabelAtLocation(sender: UITapGestureRecognizer) {
    for (_, prediction) in currentPredictions.enumerated() {
      if let classNames = self.ssdPostProcessor.classNames {
        let xOffset: Double = currentOrientation() == .landscapeRight || currentOrientation() == .landscapeLeft ? (screenWidth - screenHeight) / 2 : 0
        let yOffset: Double = currentOrientation() == .landscapeRight || currentOrientation() == .landscapeLeft ? 0 : (screenHeight - screenWidth) / 2
        let imgSize = currentOrientation() == .landscapeRight || currentOrientation() == .landscapeLeft ? screenHeight: screenWidth
        
        let textLabel = String(format: "%.2f - %@", self.sigmoid(prediction.score), classNames[prediction.detectedClass])
        
        let rect = prediction.finalPrediction.toCGRect(imgWidth: imgSize, imgHeight: imgSize, xOffset: xOffset, yOffset: yOffset)
        let screenCentre : CGPoint = CGPoint(x: rect.midX, y: rect.midY)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
          let anchor = ARAnchor(transform: closestResult.worldTransform)
          sceneView.session.add(anchor: anchor)

          let formatter = DateFormatter()
          formatter.dateFormat = "hh:mm:ss"
          let timeString = formatter.string(from: Date())
          anchorLabels[anchor.identifier] = "\(textLabel)\n\(timeString)"
        }
      }
    }
  }
}
