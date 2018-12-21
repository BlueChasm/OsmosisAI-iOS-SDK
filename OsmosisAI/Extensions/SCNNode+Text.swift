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


public extension SCNNode {
  convenience init(withText text : String, position: SCNVector3) {
    let bubbleDepth : Float = 0.04
    
    // TEXT BILLBOARD CONSTRAINT
    let billboardConstraint = SCNBillboardConstraint()
    billboardConstraint.freeAxes = SCNBillboardAxis.Y
    
    // BUBBLE-TEXT
    let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
    bubble.font = UIFont(name: "Futura", size: 0.18)?.withTraits(traits: .traitBold)
    bubble.firstMaterial?.diffuse.contents = UIColor.orange
    bubble.firstMaterial?.specular.contents = UIColor.black
    bubble.firstMaterial?.isDoubleSided = true
    bubble.chamferRadius = CGFloat(bubbleDepth)
    bubble.alignmentMode = CATextLayerAlignmentMode.center.rawValue
    
    // BUBBLE NODE
    let (minBound, maxBound) = bubble.boundingBox
    let bubbleNode = SCNNode(geometry: bubble)
    bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
    bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
    bubbleNode.simdPosition = simd_float3.init(x: 0.05, y: 0.01, z: 0)
    
    self.init()
    addChildNode(bubbleNode)
    constraints = [billboardConstraint]
    self.position = position
  }
  
  func move(_ position: SCNVector3)  {
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.4
    SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
    self.position = position
    opacity = 1
    SCNTransaction.commit()
  }
  
  func hide()  {
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 2.0
    SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
    opacity = 0
    SCNTransaction.commit()
  }
  
  func show()  {
    opacity = 0
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.4
    SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
    opacity = 1
    SCNTransaction.commit()
  }
}

private extension UIFont {
  // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
  func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
    let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
    return UIFont(descriptor: descriptor!, size: 0)
  }
}

