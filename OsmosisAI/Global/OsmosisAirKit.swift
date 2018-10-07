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


open class OsmosisAirKit {
  
  public class func initialize(clientID: String, secret: String) {
    Authentication.shared.clientID = clientID
    Authentication.shared.clientSecret = secret
  }
  
  public class func login(email: String, password: String, result: ((Bool?, Error?) -> Void)? = nil) {
    Authentication.shared.authenticate(email: email, password: password, result: result)
  }
}
