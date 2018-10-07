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

public enum ClassifierKind: String {
  case boundedBox = "boundedbox_trainer"
  case visionAI = "visionai_trainer"
  case unknown = "unknown"
}

enum FileExtension: String {
  case coreML = "mlmodelc"
  case text   = "txt"
}

public enum StatusType: Int {
  case deployed = 0
  case ready
  case training
  case unknown
}

public class Classifier : Mappable {
  
  // MARK: - Properties
  
  public var id: Int! {
    didSet {
      complete = graphFileExists() && labelFileExists()
    }
  }
  public var health: Int?
  public var classDescription: String?
  public var imageURL: String?
  var kindString: String?
  public var kind: ClassifierKind = .visionAI
  public var lenses: [Int]?
  public var title: String?
  public var results: ClassifierResult?
  
  public var complete = false
  public var isBuiltIn = false
  
  public var image: UIImage?
  public var labels = [Label]()
  
  public var graphFileURL: URL?
  public var labelsFileURL: URL? {
    didSet {
      guard let l = labelsFileURL,
        let labelsString = try? String(contentsOf: l) else { return }
      labels = Label.parseLabelsFromString(string: labelsString).sorted(by: { $0.id < $1.id })
    }
  }

  public var status = StatusType.unknown
  
  // MARK: - Object Lifecycle
  
  convenience required public init?(map: Map) { self.init() }
  
  public func mapping(map: Map) {
    id <- map["id"]
    health <- map["health"]
    classDescription <- map["description"]
    imageURL <- map["image"]
    kindString <- map["kind"]
    lenses <- map["lenses"]
    title <- map["title"]
    labels <- map["labels"]
    results <- map["results"]
    
    let s = kindString ?? "unknown"
    kind = ClassifierKind(rawValue: s) ?? .visionAI
  }
  
  
  // MARK: - Public Methods
  
  public func localFileURL(fileExtension: String) -> URL? {
    guard let subFolderPath = dataFolderURL() else { return nil }
    let graphPath = "\(id!)" + ".\(fileExtension)"
    return subFolderPath.appendingPathComponent(graphPath)
  }
  
  public func graphFileExists() -> Bool {
    guard let graphResult = localFileURL(fileExtension: FileExtension.coreML.rawValue) else { return false }
    return FileManager.default.fileExists(atPath: graphResult.absoluteString)
  }
  
  public func labelFileExists() -> Bool {
    guard let labelResult = localFileURL(fileExtension: FileExtension.text.rawValue) else { return false }
    return FileManager.default.fileExists(atPath: labelResult.absoluteString)
  }
    
  
  public func getClassifierResults(result: @escaping (Classifier?, NSError?) -> Void) {
    guard let i = id else {
      let error = NSError(domain: "TokenDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid ID for classifier"])
      result(nil, error)
      return
    }
    
    let url = "\(Constants.URLBase)/api/classifiers/\(i)/train/"
    Alamofire.request(url, method: .get, headers: ModelHelper.getHeader()).responseJSON { [weak self] response in
      guard let `self` = self else {
        result(nil, nil)
        return
      }
      
      if let error = response.result.error {
        print(error)
        result(nil, error as NSError?)
        return
      } else if let statusCode = response.response?.statusCode, statusCode != 200 {
        guard let json = response.result.value as? [String : Any] else {
          let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid server response"])
          result(nil, error)
          return
        }
        
        let errorString = json["detail"] as? String ?? "Unknown Error"
        let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : errorString])
        result(nil, error)
        return
      }
      
      print(response.result.value ?? "Empty")
      
      guard let res = response.result.value as? [[String : Any]],
        let r = res.first else {
          let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid server response"])
          result(nil, error)
          return
          
      }
      
      guard let resultsStrings = r["results"] as? [[String : Any]] else {
        let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid server response"])
        result(nil, error)
        return
      }
      
      var labelURL: String?
      var coreMLURL: String?
      
      for location in resultsStrings {
        guard let type = location["result_type"] as? String else { continue }
        
        if type == "label_map" {
          labelURL = location["result_location"] as? String
        }
        
        if type == "coreml" {
          coreMLURL = location["result_location"] as? String
        }
      }
      
      guard let l = labelURL,
        let c = coreMLURL else {
          let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid server response"])
          result(nil, error)
          return
      }

      self.results = ClassifierResult(labelsURL: l, graphURL: c)
      
      if self.graphFileExists() {
        self.graphFileURL = self.localFileURL(fileExtension: FileExtension.coreML.rawValue)
      }
      
      if self.labelFileExists() {
        if let localPathString = self.localFileURL(fileExtension: FileExtension.text.rawValue)?.absoluteString {
          self.labelsFileURL = URL(fileURLWithPath: localPathString)
        }
      }
     
      result(self, nil)
/*      let metaUrl = "\(Constants.URLBase)/api/classifiers/\(i)/metadata/"
      Alamofire.request(metaUrl, method: .get, headers: ModelHelper.getHeader()).responseJSON { [weak self] response in
        guard let `self` = self else {
          result(nil, nil)
          return
        }
        
        if let error = response.result.error {
          print(error)
          result(nil, error as NSError?)
          return
        } else if let statusCode = response.response?.statusCode, statusCode != 200 {
          guard let json = response.result.value as? [String : Any] else {
            let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid server response"])
            result(nil, error)
            return
          }
          
          let errorString = json["detail"] as? String ?? "Unknown Error"
          let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : errorString])
          result(nil, error)
          return
        }
        
        print(response.result.value ?? "Empty")
        
        guard let res = response.result.value as? [[String : Any]],
          let r = res.first else {
            let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid server response"])
            result(nil, error)
            return
            
        }
        
        guard let resultsStrings = r["results"] as? [[String : Any]] else {
          let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid server response"])
          result(nil, error)
          return
        }
        
        result(self, nil)
      }*/
      //
    }
  }
  
  
  // MARK: - Class Methods
  
  public class func createClassifier(title: String, lenses: [Lens], result: @escaping (Classifier?, NSError?) -> Void) {
    let lensIds = lenses.map({ return $0.id! })
    
    let params: [String : Any] = ["title" : title, "kind" : "image", "lenses" : lensIds]
    Alamofire.request(Constants.URLClassifier, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ModelHelper.getHeader()).responseJSON
      { response in
        if let error = response.result.error {
          result(nil, error as NSError?)
          return
        }
        //print(response.result.value ?? "Empty")
        result(Mapper<Classifier>().map(JSONObject: response.result.value), nil)
    }
  }
  
  
  public class func getClassifiers(result: @escaping ([Classifier]?, NSError?) -> Void) {
    Alamofire.request(Constants.URLClassifier, method: .get, headers: ModelHelper.getHeader()).responseJSON { response in
      if let error = response.result.error {
        result(nil, error as NSError?)
        return
      } else if let statusCode = response.response?.statusCode, statusCode != 200 {
        guard let json = response.result.value as? [String : Any] else {
          let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid server response"])
          result(nil, error)
          return
        }
        
        let errorString = json["detail"] as? String ?? "Unknown Error"
        let error = NSError(domain: "APIDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey : errorString])
        result(nil, error)
        return
      }
      
      print(response.result.value ?? "Empty")
      DispatchQueue.main.async {
        result(Mapper<Classifier>().mapArray(JSONArray: response.result.value as! [[String : Any]]), nil)
      }
    }
  }
  
  
  public class func deleteClassifier(classifier: Classifier, result: @escaping (Bool?, NSError?) -> Void) {
    let url = "\(Constants.URLClassifier)?training_set=\(classifier.id!)"
    Alamofire.request(url, method: .delete, headers: ModelHelper.getHeader()).responseJSON { response in
      if let error = response.result.error {
        result(nil, error as NSError?)
        return
      }
      
      result(true, nil)
    }
  }
}
