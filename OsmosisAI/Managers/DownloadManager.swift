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

public class DownloadManager {
  
  public static let shared = DownloadManager()
  
  public var downloadingClassifiers = [Downloader]()

  public func downloadClassifierFiles(classifier: Classifier) -> Downloader? {
    guard let id = classifier.id else { return nil }
    
    if id == 0 { return nil }
    
    let downloader = Downloader(classifier: classifier)
    downloader.downloadClassifier()
    
    downloadingClassifiers.append(downloader)
    
    return downloader
  }
  
  public func downloaderFromClassifier(classifier: Classifier) -> Downloader? {
    guard let id = classifier.id else { return nil }
    
    let filtered = downloadingClassifiers.filter({ $0.classifier.id == id })

    return filtered.first
  }
  
  public func classifierIsDownloading(classifier: Classifier) -> Bool {
    guard let id = classifier.id else { return false }
    
    let filtered = downloadingClassifiers.filter({ $0.classifier.id == id })

    return filtered.count > 0
  }
  
  public func removeDownloader(downloader: Downloader) {
    guard let id = downloader.classifier.id else { return }
    
    var index: Int?
    for (idx, d) in downloadingClassifiers.enumerated() {
      guard let cid = d.classifier.id else { continue }
      if cid == id { index = idx }
    }
    
    if let i = index {
      downloadingClassifiers.remove(at: i)
    }
  }
}
