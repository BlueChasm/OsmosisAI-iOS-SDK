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

public extension SCNVector3 {
  
  var length:Float {
    get {
      return sqrtf(x*x + y*y + z*z)
    }
  }
  
  func distance(toVector: SCNVector3) -> Float {
    return (self - toVector).length
  }
  
  static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
    return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
  }
  
  static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
  }
  
  static func center(_ vectors: [SCNVector3]) -> SCNVector3 {
    var x: Float = 0
    var y: Float = 0
    var z: Float = 0
    
    let size = Float(vectors.count)
    vectors.forEach {
      x += $0.x
      y += $0.y
      z += $0.z
    }
    return SCNVector3Make(x / size, y / size, z / size)
  }
}


