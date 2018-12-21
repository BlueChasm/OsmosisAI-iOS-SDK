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

public class Constants {
  static let Font17BoldSystem   = UIFont.boldSystemFont(ofSize: 17)
  static let Font15System       = UIFont.systemFont(ofSize: 15)
  static let Font18BoldSystem   = UIFont.boldSystemFont(ofSize: 18)
  static let Font14BoldSystem   = UIFont.boldSystemFont(ofSize: 14)
  static let Font16System       = UIFont.systemFont(ofSize: 16)
  
  static let OsmosisDarkBlue    = UIColor.colorWithHex(hex: 0x062f53)
  static let OsmosisLightBlue   = UIColor.colorWithHex(hex: 0x1190f5)
  public static let AppBlue     = UIColor(red: 65/255, green: 141/255, blue: 238/255, alpha: 1)
  public static let AppOrange   = UIColor(red: 225/255, green: 159/255, blue: 85/255, alpha: 1)
  
  static let ProcessingComplete         = Notification.Name("ClassifierProcessingComplete")
  static let ClassifierDownloadComplete = Notification.Name("ClassifierDownloadComplete")
  
  //static var URLBase = "https://dashboard.osmosisai.com"
  public static var URLBase          = "http://kobayashi.local.chasmforge.com:32080"
  
  static let authorizeURL     = "\(URLBase)/o/authorize/"
  static let tokenURL         = "\(URLBase)/o/token/"
  static let callbackURL      = "com.bc.osmosisai://authenticate"
  
  static let URLLenses        = "\(URLBase)/api/class/"
  static let URLImageUpload   = "\(URLBase)/api/data/"
  static let URLClassifier    = "\(URLBase)/api/classifiers/"
  static let URLBoundingBoxes = "\(URLBase)/api/boundingbox/"
}
