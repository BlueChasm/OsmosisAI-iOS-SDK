//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import Accelerate
import AVFoundation
import CoreML
import Foundation
import Vision

public class InferenceClass {
  
  // MARK: - Properties
  
  var view: UIView!
  
  var ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 90)  // Configuration of default SSD MobileNet Model
  var visionModel: VNCoreMLModel!
  let semaphore = DispatchSemaphore(value: 1)
  
  var screenHeight: Double
  var screenWidth: Double
  let numBoxes = 100
  var boundingBoxes: [BoundingBox] = []
  let multiClass = true
  
  
  // MARK: - Public Methods
  
  public init(view: UIView, classifier: Classifier? = nil) {
    self.view = view
    
    screenWidth = Double(view.frame.width)
    screenHeight = Double(view.frame.height)
    
    if let c = classifier {
      guard let v = setupDownloadedModel(classifier: c) else { fatalError("Can't load VisionML model") }
      visionModel = v
    } else {
      guard let v = setupInception() else { fatalError("Can't load Inception VisionML model") }
      visionModel = v
    }

    setupBoxes()
  }

  
  public func processSampleBuffer(sampleBuffer: CMSampleBuffer) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    
    var requestOptions:[VNImageOption : Any] = [:]
    if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
      requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
    }
    let orientation = CGImagePropertyOrientation(rawValue: UInt32(EXIFOrientation.rightTop.rawValue))
    
    let trackingRequest = VNCoreMLRequest(model: visionModel) { (request, error) in
      guard let predictions = self.processClassifications(for: request, error: error) else { return }
      DispatchQueue.main.async {
        self.drawBoxes(predictions: predictions)
      }
      self.semaphore.signal()
    }
    trackingRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
    
    self.semaphore.wait()
    do {
      let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation!, options: requestOptions)
      try imageRequestHandler.perform([trackingRequest])
    } catch {
      print(error)
      self.semaphore.signal()
      
    }
  }
  
  
  public func updateClassifier(classifier: Classifier) {
    guard let v = setupDownloadedModel(classifier: classifier) else { fatalError("Can't load VisionML model") }
    visionModel = v
  }
  
  

  // MARK: - Private Methods
  
  private func setupDownloadedModel(classifier: Classifier) -> VNCoreMLModel? {
    guard let graphURL = classifier.graphFileURL else { return nil }
    
    guard let model = try? MLModel(contentsOf: graphURL) else {
      fatalError("Can't open CoreML model")
    }
    
    guard let v = try? VNCoreMLModel(for: model) else {
      fatalError("Can't load VisionML model")
    }
    
    ssdPostProcessor = SSDPostProcessor(classifier: classifier)
    return v
  }
  
  
  private func setupInception() -> VNCoreMLModel? {
    guard let v = try? VNCoreMLModel(for: ssd_mobilenet_feature_extractor().model)
      else { fatalError("Can't load VisionML model") }
    return v
  }
  
  
  private func setupBoxes() {
    for _ in 0..<numBoxes {
      let box = BoundingBox()
      box.addToLayer(view.layer)
      self.boundingBoxes.append(box)
    }
  }
  
  
  private func processClassifications(for request: VNRequest, error: Error?) -> [Prediction]? {
    guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
      return nil
    }
    
    guard results.count == 2 else {
      return nil
    }
    
    guard let boxPredictions = results[1].featureValue.multiArrayValue,
      let classPredictions = results[0].featureValue.multiArrayValue else {
        return nil
    }
    
    let predictions = self.ssdPostProcessor.postprocess(boxPredictions: boxPredictions, classPredictions: classPredictions)
    return predictions
  }
  
  
  private func drawBoxes(predictions: [Prediction]) {
    
    for (index, prediction) in predictions.enumerated() {
      if let classNames = self.ssdPostProcessor.classNames {
        let textColor: UIColor
        let name = classNames[prediction.detectedClass]
        let textLabel = String(format: "%.2f - %@", self.sigmoid(prediction.score), name)
        
        textColor = UIColor.black
        let rect = prediction.finalPrediction.toCGRect(imgWidth: screenWidth, imgHeight: screenWidth, xOffset: 0, yOffset: (screenHeight - screenWidth)/2)
        self.boundingBoxes[index].show(frame: rect,
                                       label: textLabel,
                                       color: UIColor.red, textColor: textColor)
      }
    }
    for index in predictions.count..<self.numBoxes {
      self.boundingBoxes[index].hide()
    }
  }
  
  
  private func sigmoid(_ val:Double) -> Double {
    return 1.0/(1.0 + exp(-val))
  }
  
  
  private func softmax(_ values:[Double]) -> [Double] {
    if values.count == 1 { return [1.0]}
    guard let maxValue = values.max() else {
      fatalError("Softmax error")
    }
    let expValues = values.map { exp($0 - maxValue)}
    let expSum = expValues.reduce(0, +)
    return expValues.map({$0/expSum})
  }
  
  
  private static func softmax2(_ x: [Double]) -> [Double] {
    var x:[Float] = x.compactMap{Float($0)}
    let len = vDSP_Length(x.count)
    
    var max: Float = 0
    vDSP_maxv(x, 1, &max, len)
    
    max = -max
    vDSP_vsadd(x, 1, &max, &x, 1, len)
    
    var count = Int32(x.count)
    vvexpf(&x, x, &count)
    
    var sum: Float = 0
    vDSP_sve(x, 1, &sum, len)
    
    vDSP_vsdiv(x, 1, &sum, &x, 1, len)
    
    let y:[Double] = x.compactMap{Double($0)}
    return y
  }
  
  
  private func compensatingEXIFOrientation(deviceOrientation:UIDeviceOrientation) -> EXIFOrientation {
    switch (deviceOrientation) {
    case (.landscapeRight): return .bottomRight
    case (.landscapeLeft): return .topLeft
    case (.portrait): return .rightTop
    case (.portraitUpsideDown): return .leftBottom
      
    case (.faceUp): return .rightTop
    case (.faceDown): return .rightTop
    case (_): fallthrough
    default:
      NSLog("Called in unrecognized orientation")
      return .rightTop
    }
  }

}
