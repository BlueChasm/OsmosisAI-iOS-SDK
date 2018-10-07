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

public class LensImage: Mappable {

  // MARK: - Properties
  
  var id: Int!
  var contentType: String?
  var url: String?
  var trainingClassID: Int?
  var image: UIImage?
  
  
  // MARK: - Object Lifecycle
  
  convenience required public init?(map: Map) { self.init() }
  
  public func mapping(map: Map) {
    id <- map["id"]
    contentType <- map["content_type"]
    url <- map["data"]
    trainingClassID <- map["training_class"]
  }
  
}
