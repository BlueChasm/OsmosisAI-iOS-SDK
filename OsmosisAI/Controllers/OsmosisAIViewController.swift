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
import UIKit
import Vision


open class OsmosisAIViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  
  // MARK: - Properties
  
  @IBOutlet weak var cameraView: UIView!
  
  let semaphore = DispatchSemaphore(value: 1)
  var lastExecution = Date()
  var screenHeight: Double?
  var screenWidth: Double?
  var ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 90)
  var visionModel:VNCoreMLModel?
  
  private var textDetectionRequest: VNDetectTextRectanglesRequest?
  private var textObservations = [VNTextObservation]()
  private var tesseract = G8Tesseract(language: "eng", engineMode: .tesseractOnly)
  private var font = CTFontCreateWithName("Helvetica" as CFString, 18, nil)
  
  private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
  private lazy var captureSession: AVCaptureSession = {
    let session = AVCaptureSession()
    session.sessionPreset = AVCaptureSession.Preset.hd1280x720
    
    guard
      let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let input = try? AVCaptureDeviceInput(device: backCamera)
      else { return session }
    session.addInput(input)
    return session
  }()
  
  let numBoxes = 100
  var boundingBoxes: [BoundingBox] = []
  let multiClass = true
  
  
  // MARK: - Object Lifecycle
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    self.cameraView?.layer.addSublayer(self.cameraLayer)
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
    self.captureSession.addOutput(videoOutput)

    screenWidth = Double(view.frame.width)
    screenHeight = Double(view.frame.height)
    
    setupBoxes()
  }
  
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  
    
    if let c = SessionData.shared.currentClassifier {
      setupDownloadedModel(classifier: c)
    } else {
      setupInception()
    }

    self.captureSession.startRunning()
    
  }
  
  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    cameraLayer.frame = cameraView.layer.bounds
  }
  
  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    self.captureSession.stopRunning()
  }
  
  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.cameraLayer.frame = self.cameraView?.bounds ?? .zero
  }
  
  
  // MARK: - Public Methods
  
  public class func setup(ocr: Bool? = false, storyboard: UIStoryboard? = nil) -> OsmosisAIViewController {    
    if let s = storyboard {
      guard let vc = s.instantiateInitialViewController() as? OsmosisAIViewController else {
        fatalError("When using a custom storyboard, please set your OsmosisAIViewController as the initial view controller.")
      }
      return vc
    }
    
    let frameworkBundle = Bundle(for: OsmosisAIViewController.self)
    guard let viewController = UIStoryboard(name: "OsmosisAIViewController", bundle: frameworkBundle).instantiateInitialViewController() as? OsmosisAIViewController else {
      fatalError("Unable to instantiate OsmosisAIViewController")
    }
    return viewController
  }
  
  public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    guard let visionModel = self.visionModel else {
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
  
  
  // MARK: - Private Methods
  
  func handleOCR(sampleBuffer: CMSampleBuffer) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    
    var imageRequestOptions = [VNImageOption: Any]()
    if let cameraData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
      imageRequestOptions[.cameraIntrinsics] = cameraData
    }
    let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: imageRequestOptions)
    do {
      try imageRequestHandler.perform([textDetectionRequest!])
    }
    catch {
      print("Error occured \(error)")
    }
    var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let transform = ciImage.orientationTransform(for: CGImagePropertyOrientation(rawValue: 6)!)
    ciImage = ciImage.transformed(by: transform)
    let size = ciImage.extent.size
    var recognizedTextPositionTuples = [(rect: CGRect, text: String)]()
    for textObservation in textObservations {
      guard let rects = textObservation.characterBoxes else {
        continue
      }
      var xMin = CGFloat.greatestFiniteMagnitude
      var xMax: CGFloat = 0
      var yMin = CGFloat.greatestFiniteMagnitude
      var yMax: CGFloat = 0
      for rect in rects {
        
        xMin = min(xMin, rect.bottomLeft.x)
        xMax = max(xMax, rect.bottomRight.x)
        yMin = min(yMin, rect.bottomRight.y)
        yMax = max(yMax, rect.topRight.y)
      }
      let imageRect = CGRect(x: xMin * size.width, y: yMin * size.height, width: (xMax - xMin) * size.width, height: (yMax - yMin) * size.height)
      let context = CIContext(options: nil)
      guard let cgImage = context.createCGImage(ciImage, from: imageRect) else {
        continue
      }
      let uiImage = UIImage(cgImage: cgImage)
      tesseract?.image = uiImage
      tesseract?.recognize()
      guard var text = tesseract?.recognizedText else {
        continue
      }
      text = text.trimmingCharacters(in: CharacterSet.newlines)
      if !text.isEmpty {
        let x = xMin
        let y = 1 - yMax
        let width = xMax - xMin
        let height = yMax - yMin
        recognizedTextPositionTuples.append((rect: CGRect(x: x, y: y, width: width, height: height), text: text))
      }
    }
    textObservations.removeAll()
    DispatchQueue.main.async {
      let viewWidth = self.view.frame.size.width
      let viewHeight = self.view.frame.size.height
      guard let sublayers = self.view.layer.sublayers else {
        return
      }
      for layer in sublayers[1...] {
        
        if let _ = layer as? CATextLayer {
          layer.removeFromSuperlayer()
        }
      }
      for tuple in recognizedTextPositionTuples {
        let textLayer = CATextLayer()
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.font = self.font
        var rect = tuple.rect
        
        rect.origin.x *= viewWidth
        rect.size.width *= viewWidth
        rect.origin.y *= viewHeight
        rect.size.height *= viewHeight
        
        // Increase the size of text layer to show text of large lengths
        rect.size.width += 100
        rect.size.height += 100
        
        textLayer.frame = rect
        textLayer.string = tuple.text
        textLayer.foregroundColor = UIColor.green.cgColor
        self.view.layer.addSublayer(textLayer)
      }
    }
  }
  
  func setupBoxes() {
    for _ in 0..<numBoxes {
      let box = BoundingBox()
      box.addToLayer(view.layer)
      self.boundingBoxes.append(box)
    }
  }

  func setupDownloadedModel(classifier: Classifier) {
    guard let graphURL = classifier.graphFileURL else { return }
    
    guard let model = try? MLModel(contentsOf: graphURL) else {
      fatalError("Can't open CoreML model")
    }
    
    guard let visionModel = try? VNCoreMLModel(for: model) else {
      fatalError("Can't load VisionML model")
    }
    
    ssdPostProcessor = SSDPostProcessor(classifier: classifier)
    self.visionModel = visionModel
  }
  
  func setupInception() {
    guard let visionModel = try? VNCoreMLModel(for: ssd_mobilenet_feature_extractor().model)
      else { fatalError("Can't load VisionML model") }
    self.visionModel = visionModel
  }
  
  func processClassifications(for request: VNRequest, error: Error?) -> [Prediction]? {
    let thisExecution = Date()
    //let executionTime = thisExecution.timeIntervalSince(lastExecution)
    //let framesPerSecond:Double = 1/executionTime
    lastExecution = thisExecution
    
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
    //    DispatchQueue.main.async {
    //      self.frameLabel.text = "FPS: \(framesPerSecond.format(f: ".3"))"
    //    }
    
    let predictions = self.ssdPostProcessor.postprocess(boxPredictions: boxPredictions, classPredictions: classPredictions)
    return predictions
  }
  
  func drawBoxes(predictions: [Prediction]) {
    
    for (index, prediction) in predictions.enumerated() {
      if let classNames = self.ssdPostProcessor.classNames {
        let textColor: UIColor
        let name = classNames[prediction.detectedClass]
        let textLabel = String(format: "%.2f - %@", self.sigmoid(prediction.score), name)
        
        textColor = UIColor.black
        let rect = prediction.finalPrediction.toCGRect(imgWidth: self.screenWidth!, imgHeight: self.screenWidth!, xOffset: 0, yOffset: (self.screenHeight! - self.screenWidth!)/2)
        self.boundingBoxes[index].show(frame: rect,
                                       label: textLabel,
                                       color: UIColor.red, textColor: textColor)
      }
    }
    for index in predictions.count..<self.numBoxes {
      self.boundingBoxes[index].hide()
    }
  }
  
  func sigmoid(_ val:Double) -> Double {
    return 1.0/(1.0 + exp(-val))
  }
  
  func softmax(_ values:[Double]) -> [Double] {
    if values.count == 1 { return [1.0]}
    guard let maxValue = values.max() else {
      fatalError("Softmax error")
    }
    let expValues = values.map { exp($0 - maxValue)}
    let expSum = expValues.reduce(0, +)
    return expValues.map({$0/expSum})
  }
  
  public static func softmax2(_ x: [Double]) -> [Double] {
    var x:[Float] = x.compactMap{Float($0)}
    let len = vDSP_Length(x.count)
    
    // Find the maximum value in the input array.
    var max: Float = 0
    vDSP_maxv(x, 1, &max, len)
    
    // Subtract the maximum from all the elements in the array.
    // Now the highest value in the array is 0.
    max = -max
    vDSP_vsadd(x, 1, &max, &x, 1, len)
    
    // Exponentiate all the elements in the array.
    var count = Int32(x.count)
    vvexpf(&x, x, &count)
    
    // Compute the sum of all exponentiated values.
    var sum: Float = 0
    vDSP_sve(x, 1, &sum, len)
    
    // Divide each element by the sum. This normalizes the array contents
    // so that they all add up to 1.
    vDSP_vsdiv(x, 1, &sum, &x, 1, len)
    
    let y:[Double] = x.compactMap{Double($0)}
    return y
  }
  
  func compensatingEXIFOrientation(deviceOrientation:UIDeviceOrientation) -> EXIFOrientation
  {
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
