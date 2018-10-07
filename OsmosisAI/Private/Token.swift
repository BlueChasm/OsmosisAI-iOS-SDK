//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import Alamofire
import Foundation

class Token: NSObject, NSCoding {
  
  // MARK: - Properties
  
  let accessToken: String
  let refreshToken: String
  let expiration: TimeInterval
  
  // MARK: - Object Lifecycle
  
  init(json: [String : Any]) {
    accessToken = json["access_token"] as? String ?? ""
    refreshToken = json["refresh_token"] as? String ?? ""
    
    let interval = Date().timeIntervalSince1970
    if let e = json["expires_in"] as? Double {  expiration = interval + e }
    else { expiration = interval }
  }
  
  
  // MARK: - NSCoder
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(accessToken, forKey: "accessToken")
    aCoder.encode(refreshToken, forKey: "refreshToken")
    aCoder.encode(expiration, forKey: "expiration")
  }
  
  required init?(coder aDecoder: NSCoder) {
    accessToken = aDecoder.decodeObject(forKey: "accessToken") as? String ?? ""
    refreshToken = aDecoder.decodeObject(forKey: "refreshToken") as? String ?? ""
    expiration = aDecoder.decodeDouble(forKey: "expiration")
  }
  
  
  // MARK: - Class Methods
  
  class func login(email: String, password: String, result: @escaping (Bool?, Error?) -> Void) {
    guard let clientID = Authentication.shared.clientID,
      let secret = Authentication.shared.clientSecret else {
        let error = OAIError.missingTokens
        print(error.localizedDescription)
        result(false, error)
        return
    }
    
    let params = ["grant_type" : "password",
                  "username" : email,
                  "password" : password,
                  "scope" : "train deploy",
                  "client_id" : clientID,
                  "client_secret" : secret]

    let headers = ["Content-Type" : "application/x-www-form-urlencoded",
                   "Accept" : "application/json"]

    Alamofire.request(Constants.tokenURL, method: .post, parameters: params, encoding: URLEncoding.default, headers: headers).responseJSON
      { response in
        
        if let error = response.result.error {
          print(error)
          result(false, error as NSError?)
          return
        }
        
        guard let json = response.result.value as? [String : Any] else {
          result(false, OAIError.loginFailed)
          return
        }
        
        if let errorString = json["error"] as? String {
          let error = NSError(domain: "TokenDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Login failed.  Please check your email and password.\n\(errorString)"])
          result(false, error)
          return
        }
        
        let token = Token(json: json)
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: token)
        UserDefaults.standard.set(encodedData, forKey: "token")
        
        result(true, nil)
    }
  }
  
  class func refreshCurrentToken(result: ((Bool?, Error?) -> Void)? = nil) {
    guard let data = UserDefaults.standard.object(forKey: "token"),
      let token = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as? Token else {
        result?(false, nil)
        return
    }
    
    guard let clientID = Authentication.shared.clientID,
      let secret = Authentication.shared.clientSecret else {
        let error = OAIError.missingTokens
        print(error.localizedDescription)
        result?(false, error)
        return
    }
    
    let authString = String(format: "%@:%@", clientID, secret)
    let authData = authString.data(using: String.Encoding.utf8)!
    let base64AuthString = authData.base64EncodedString()
    
    let params: [String : String] = ["grant_type" : "refresh_token",
                                     "refresh_token" : token.refreshToken]
    let headers = ["Authorization" : "Basic \(base64AuthString)",
                   "Content-Type" : "application/x-www-form-urlencoded",
                   "Accept" : "application/json"]
    
    Alamofire.request(Constants.tokenURL, method: .post, parameters: params, encoding: URLEncoding.default, headers: headers).responseJSON
      { response in
        if let error = response.result.error {
          result?(false, error as NSError?)
          return
        }
        
        guard let json = response.result.value as? [String : Any] else {
          result?(false, nil)
          return
        }
        
        if let errorString = json["error"] as? String {
          print(errorString)
          let error = NSError(domain: "TokenDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : errorString])
          result?(false, error)
          return
        }
        
        
        let token = Token(json: json)
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: token)
        UserDefaults.standard.set(encodedData, forKey: "token")
        
        result?(true, nil)
    }
  }
  
  class func requireRefresh() -> Bool {
    if let data = UserDefaults.standard.object(forKey: "token"),
      let token = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as? Token {
      print("Access: " + token.accessToken)
      print("Refresh: " + token.refreshToken)
      let interval = Date().timeIntervalSince1970
      if token.expiration > interval { return false }
    }
    
    return true
  }
  
  class func oauthToken() -> String? {
    return "kwnlkjaSFDJijoifjlsf3rE@s"
    
    /*if let data = UserDefaults.standard.object(forKey: "token"),
      let token = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as? Token {
      return token.accessToken
    }
    
    return nil*/
  }
}
