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

class ModelHelper {
  
  class func getHeader() -> [String : String] {
    var header = [String : String]()
    
    if let token = Token.oauthToken() {
      header["Authorization"] = "Bearer \(token)"
    }
    header["Content-Type"] = "application/json"
    return header
  }
  
  deinit {
    print("deInit ModelHelper")
  }

}
