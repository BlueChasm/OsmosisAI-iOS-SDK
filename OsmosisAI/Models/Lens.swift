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
import ObjectMapper

public class Lens: Mappable {
  
  // MARK: - Properties

  public var id: Int!
  public var thumbnailURL: String?
  public var imageCount: Int?
  public var lensDescription: String?
  public var title: String?
  public var thumbnail: UIImage?
  public var healthChecks = [HealthCheck]()
  public var metadata = [String : String]()
  
  var healthCheckDictionary: [String : Any]?
  
  
  // MARK: - Object Lifecycle
  
  convenience required public init?(map: Map) { self.init() }
  
  public func mapping(map: Map) {
    id <- map["id"]
    thumbnailURL <- map["image"]
    imageCount <- map["data_count"]
    lensDescription <- map["description"]
    title <- map["title"]
    
    healthCheckDictionary <- map["health"]
    if let checks = healthCheckDictionary?["checks"] as? [[String : Any]] {
      healthChecks = Mapper<HealthCheck>().mapArray(JSONArray: checks)
    }
    
    metadata <- map["metadata"]
  }
  
  
  public class func getLenses(result: @escaping ([Lens]?, NSError?) -> Void) {
    Alamofire.request(Constants.URLLenses, method: .get, headers: ModelHelper.getHeader()).responseJSON { response in
      if let error = response.result.error {
        result(nil, error as NSError?)
        return
      }
      
      if let detailDict = response.result.value as? [String : String],
        let detail = detailDict["detail"] {
        let error = NSError(domain: "LensesDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : detail])
        result(nil, error)
        return
      }
      
      print(response.result.value ?? "Empty")
      
      result(Mapper<Lens>().mapArray(JSONArray: response.result.value as! [[String : Any]]), nil)
    }
  }
  
  public class func addLens(title: String, result: @escaping (Lens?, NSError?) -> Void) {
    let params = ["title" : title]
    Alamofire.request(Constants.URLLenses, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ModelHelper.getHeader()).responseJSON
      { response in
        
        if let error = response.result.error {
          result(nil, error as NSError?)
          return
        }
        
        if let detailDict = response.result.value as? [String : String],
          let detail = detailDict["detail"] {
          let error = NSError(domain: "LensesDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : detail])
          result(nil, error)
          return
        }
        
        result(Mapper<Lens>().map(JSONObject: response.result.value), nil)
    }
  }
  
  public class func removeLens(lens: Lens, result: @escaping (NSError?) -> Void) {
    guard let lensID = lens.id else { return }

    let url = Constants.URLLenses + "?training_class=\(lensID)"

    Alamofire.request(url, method: .delete, encoding: JSONEncoding.default, headers: ModelHelper.getHeader()).responseJSON
      { response in
        if let error = response.result.error {
          result(error as NSError?)
          return
        }
        
        result(nil)
    }
  }
  
  public class func getLensDetail(lens: Lens, result: @escaping ([LensImage]?, NSError?) -> Void) {
    guard let lensID = lens.id else { return }
    
    let url = Constants.URLImageUpload + "?training_class=\(lensID)"

    Alamofire.request(url, method: .get, headers: ModelHelper.getHeader()).responseJSON { response in
      
      if let error = response.result.error {
        result(nil, error as NSError?)
        return
      }
      
      if let detailDict = response.result.value as? [String : String],
        let detail = detailDict["detail"] {
        let error = NSError(domain: "LensesDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : detail])
        result(nil, error)
        return
      }
      
      result(Mapper<LensImage>().mapArray(JSONArray: response.result.value as! [[String : Any]]), nil)
    }
    
  }
}
