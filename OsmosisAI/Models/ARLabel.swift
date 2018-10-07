//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import Foundation
import ARKit

class ARLabel {
  let name: String
  let node: SCNNode
  var hidden: Bool {
    get{
      return node.opacity != 1
    }
  }
  var timestamp: TimeInterval {
    didSet {
      updated = Date()
    }
  }
  private(set) var updated = Date()
  
  init(name: String, node: SCNNode, timestamp: TimeInterval) {
    self.name = name
    self.node = node
    self.timestamp = timestamp
  }
}

extension Date {
  func isAfter(seconds: Double) -> Bool {
    let elapsed = Date.init().timeIntervalSince(self)
    
    if elapsed > seconds {
      return true
    }
    return false
  }
}
