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
import Vision


protocol BoxServiceDelegate: class {
  func boxService(_ service: BoxService, didDetect images: [UIImage])
}

final class BoxService {
  private var layers: [CALayer] = []
  
  weak var delegate: BoxServiceDelegate?
  
  func handle(cameraLayer: AVCaptureVideoPreviewLayer, image: UIImage, results: [VNTextObservation], on view: UIView) {
    reset()
    
    var images: [UIImage] = []
    let results = results.filter({ $0.confidence > 0.5 })
    
    layers = results.map({ result in
      let layer = CALayer()
      view.layer.addSublayer(layer)
      layer.borderWidth = 2
      layer.borderColor = UIColor.green.cgColor
      
      do {
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: image.size.width, y: -image.size.height)
        transform = transform.translatedBy(x: 0, y: -1)
        let rect = result.boundingBox.applying(transform)
        
        let scaleUp: CGFloat = 0.2
        let biggerRect = rect.insetBy(
          dx: -rect.size.width * scaleUp,
          dy: -rect.size.height * scaleUp
        )
        
        if let croppedImage = crop(image: image, rect: biggerRect) {
          images.append(croppedImage)
        }
      }
      
      do {
        let rect = cameraLayer.layerRectConverted(fromMetadataOutputRect: result.boundingBox)
        layer.frame = rect
      }
      
      return layer
    })
    
    delegate?.boxService(self, didDetect: images)
  }
  
  private func crop(image: UIImage, rect: CGRect) -> UIImage? {
    guard let cropped = image.cgImage?.cropping(to: rect) else {
      return nil
    }
    
    return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
  }
  
  private func reset() {
    layers.forEach {
      $0.removeFromSuperlayer()
    }
    
    layers.removeAll()
  }
}
