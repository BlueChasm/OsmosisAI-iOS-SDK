//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

/*import SwiftOCR
import TesseractOCR

protocol OCRServiceDelegate: class {
  func ocrService(_ service: OCRService, didDetect text: String)
}

final class OCRService {
  private let instance = SwiftOCR()
  private let tesseract = G8Tesseract(language: "eng")!
  
  weak var delegate: OCRServiceDelegate?
  
  init() {
    tesseract.engineMode = .tesseractCubeCombined
    tesseract.pageSegmentationMode = .singleBlock
  }
  
  func handle(image: UIImage) {
    handleWithTesseract(image: image)
  }
  
  private func handleWithSwiftOCR(image: UIImage) {
    instance.recognize(image, { string in
      DispatchQueue.main.async {
        self.delegate?.ocrService(self, didDetect: string)
      }
    })
  }
  
  private func handleWithTesseract(image: UIImage) {
    tesseract.image = image.g8_blackAndWhite()
    tesseract.recognize()
    let text = tesseract.recognizedText ?? ""
    delegate?.ocrService(self, didDetect: text)
  }
}
*/
