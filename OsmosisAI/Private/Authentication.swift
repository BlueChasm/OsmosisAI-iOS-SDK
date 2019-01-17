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

class Authentication {
  
  static let shared = Authentication()
  
  var clientID: String?
  var clientSecret: String?
  
  var isAuthenticated: Bool = false
  
  func authenticate(email: String, password: String, result: ((Bool?, Error?) -> Void)? = nil) {
    Token.login(email: email, password: password) { [weak self] (success, error) in
      if let err = error {
        result?(false, err)
        return
      }
      
      guard let s = success,
        s == true else {
          result?(false, OAIError.unknownError)
        return
      }
      
      self?.isAuthenticated = true
      result?(true, nil)
    }
  }

}
