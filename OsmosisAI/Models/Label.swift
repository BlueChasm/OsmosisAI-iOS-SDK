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
  
public class Label {
  var id: Int!
  var name: String!
  
  init(id: Int, name: String) {
    self.id = id
    self.name = name
  }
  
  class func parseLabelsFromString(string: String) -> [Label] {
    var labels = [Label]()
    
    let components = string.components(separatedBy: "item")
    
    for item in components {
      if item.count == 0 { continue }
      
      let itemComponents = item.components(separatedBy: "name")
      
      guard itemComponents.count == 2,
        let idString = itemComponents.first else { continue }
      
      
      let nameComponents = itemComponents[1].components(separatedBy: "'")
      guard nameComponents.count == 3 else { continue }
      
      let id = idString.trimmingCharacters(in: CharacterSet(charactersIn: "01234567890").inverted)
      let name = nameComponents[1]
      
      guard let i = Int(id) else { continue }
      
      let label = Label(id: i, name: name)
      labels.append(label)
    }
    return labels
  }
}
