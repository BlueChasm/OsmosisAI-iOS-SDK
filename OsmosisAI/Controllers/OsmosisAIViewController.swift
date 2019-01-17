//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import AVFoundation
import UIKit


open class OsmosisAIViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  
  // MARK: - Properties
  
  @IBOutlet weak var cameraView: UIView!
  
  private var inferenceClass: InferenceClass?
  
  private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
  private lazy var captureSession: AVCaptureSession = {
    let session = AVCaptureSession()
    session.sessionPreset = AVCaptureSession.Preset.hd1280x720
    
    guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let input = try? AVCaptureDeviceInput(device: backCamera)
      else { return session }
    session.addInput(input)
    return session
  }()
  
  
  // MARK: - Object Lifecycle
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    self.cameraView?.layer.addSublayer(self.cameraLayer)
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
    self.captureSession.addOutput(videoOutput)
    
    inferenceClass = InferenceClass(view: view)
  }
  
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)  
    
    if let c = SessionData.shared.currentClassifier {
      inferenceClass?.updateClassifier(classifier: c)
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
  
  public class func setup(storyboard: UIStoryboard? = nil) -> OsmosisAIViewController {    
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
    inferenceClass?.processSampleBuffer(sampleBuffer: sampleBuffer)
  }
}
