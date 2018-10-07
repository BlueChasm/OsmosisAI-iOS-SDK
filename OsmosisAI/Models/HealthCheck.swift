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

public enum CriteriaType: String {
  case imageCount = "image_count_criteria"
  case unknown = "unknown"
}


public class HealthCheck : Mappable {
  
  // MARK: - Properties
  
  var criteriaString: String?
  var criteria: CriteriaType?
  var messages: [String]?
  
  
  // MARK: - Object Lifecycle

  convenience required public init?(map: Map) { self.init() }

  public func mapping(map: Map) {
    criteriaString <- map["criteria"]
    messages <- map["messages"]
    
    let s = criteriaString ?? "unknown"
    criteria = CriteriaType(rawValue: s) ?? .unknown
  }
    
}
