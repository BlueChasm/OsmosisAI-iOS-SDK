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


public enum OAIError: Error {
  
  case missingCredentials
  case missingTokens
  case loginFailed
  case unknownError
  
  public var localizedDescription: String {
    switch self {
    case .missingCredentials:   return "Login failed.  Credentials not provided."
    case .missingTokens:        return "ClientID or secred not set.  Please see documentation and initialize the framework in your App Delegate."
    case .loginFailed:          return "Login failed.  Please check your email or password."
    case .unknownError:         return "Unknown error."
    }
  }
}
