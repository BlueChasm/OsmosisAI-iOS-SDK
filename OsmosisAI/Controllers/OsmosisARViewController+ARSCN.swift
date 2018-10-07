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
import Foundation

extension OsmosisARViewController : ARSCNViewDelegate, ARSessionDelegate, ARSKViewDelegate {
  
  public func session(_ session: ARSession, didUpdate frame: ARFrame) {
    guard currentBuffer == nil,
      case .normal = frame.camera.trackingState else {
      return
    }
    
    currentBuffer = frame.capturedImage
    classifyCurrentImage(frame: frame)
  }
  
  public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
  }
  
  
  public func view(_ view: ARSKView, didAdd node: SKNode, for anchor: ARAnchor) {
    guard let labelText = anchorLabels[anchor.identifier] else {
      fatalError("missing expected associated label for anchor")
    }
    let label = TemplateLabelNode(text: labelText)
    node.addChild(label)
  }

}
