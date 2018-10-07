//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import SpriteKit

/// - Tag: TemplateLabelNode
class TemplateLabelNode: SKReferenceNode {
    
    private let text: String
    
    init(text: String) {
        self.text = text
        // Force call to designated init(fileNamed: String?), not convenience init(fileNamed: String)
        super.init(fileNamed: Optional.some("LabelScene"))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didLoad(_ node: SKNode?) {
        // Apply text to both labels loaded from the template.
        guard let parent = node?.childNode(withName: "LabelNode") else {
            fatalError("misconfigured SpriteKit template file")
        }
        for case let label as SKLabelNode in parent.children {
            label.name = text
            label.text = text
        }
    }
}
