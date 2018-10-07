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
import UIKit

enum EXIFOrientation : Int32 {
  case topLeft = 1
  case topRight
  case bottomRight
  case bottomLeft
  case leftTop
  case rightTop
  case rightBottom
  case leftBottom
  
  var isReflect:Bool {
    switch self {
    case .topLeft,.bottomRight,.rightTop,.leftBottom: return false
    default: return true
    }
  }
}

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

extension CGImagePropertyOrientation {
  init(_ deviceOrientation: UIDeviceOrientation) {
    switch deviceOrientation {
    case .portraitUpsideDown: self = .left
    case .landscapeLeft:      self = .up
    case .landscapeRight:     self = .down
    default:                  self = .right
    }
  }
}

func delay(_ delay:Double, closure:@escaping ()->()) {
  DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func DMQ(closure:@escaping ()->()) {
  DispatchQueue.main.async {
    closure()
  }
}

func DBQ(closure:@escaping ()->()) {
  DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
    closure()
  }
}

func listFilesFromDataFolder() -> [String]?  {
  let fileMngr = FileManager.default;
  let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
  //let subFolderPath = docs.appending("/data")
  return try? fileMngr.contentsOfDirectory(atPath:docs)
}

public func dataFolderPath() -> String {
  let fileMngr = FileManager.default;
  let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
  return docs
}

func dataFolderURL() -> URL? {
  return URL(string: dataFolderPath())
}
