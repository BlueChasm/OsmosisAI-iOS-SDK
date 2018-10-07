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
import ISMessages

public class ClassifierManager {
  
  public static let shared = ClassifierManager()

  public var allClassifiers = [Classifier]()
  public var processingClassifierIDs = [Int]()
  
  var timer: Timer? {
    didSet { oldValue?.invalidate() }
  }
  
  var testTimer: Timer? {
    didSet { oldValue?.invalidate() }
  }
  
  var doTest = false
  
  public func setup() {
    timer = Timer.scheduledTimer(timeInterval: TimeInterval(5), target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
  }
  
  public func shutdown() {
    timer?.invalidate()
    testTimer?.invalidate()
  }
  
  @objc func testTimerFired() {
    doTest = true
  }
  
  @objc func timerFired() {
    
    Classifier.getClassifiers { [weak self] (classifiers, error) in
      guard let cs = classifiers,
        let `self` = self else { return }

      self.allClassifiers = cs
      
      var processing = [Int]()
      for c in self.allClassifiers {
        if c.complete == false {
          processing.append(c.id!)
        }
      }
      
      if self.doTest == true {
        self.doTest = false
        processing = [34, 36, 35, 57]
      }
      
      if processing.count < self.processingClassifierIDs.count {
        let set1: Set<Int> = Set(processing)
        let set2: Set<Int> = Set(self.processingClassifierIDs)
        
        let diff: Set<Int>  = set1.symmetricDifference(set2)

        if let id = diff.first {
          let filtered = self.allClassifiers.filter({$0.id == id})

          if let c = filtered.first {
            let title = c.title ?? ""
            
            ISMessages.showCardAlert(withTitle: "Classifier Complete", message: "We have finished processing `\(title)'.  It is now available for deployment", duration: 5, hideOnSwipe: true, hideOnTap: false, alertType: .success, alertPosition: .top, didHide: nil)
          }
        }
      }

      self.processingClassifierIDs = [Int]()
      for c in self.allClassifiers {
        if c.complete == false {
          self.processingClassifierIDs.append(c.id!)
        }
      }
      
    }
  }
}
