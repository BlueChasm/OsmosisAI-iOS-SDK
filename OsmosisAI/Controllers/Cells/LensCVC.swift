//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import SDWebImage
import UIKit

protocol LensCVCDelegate: class {
  func lensCVC(_ cell: LensCVC, didSelectLens lens: Lens)
  func lensCVC(_ cell: LensCVC, didSelectImage lens: Lens)
  func lensCVC(_ cell: LensCVC, didSelectForTrain lens: Lens)
  func lensCVC(_ cell: LensCVC, didDeSelectForTrain lens: Lens)
  func lensCVCShouldShowLensCountAlert(_ cell: LensCVC)
  func lensCVC(_ cell: LensCVC, shouldDeleteLens lens: Lens)
}


public class LensCVC: UICollectionViewCell {
  
  // MARK: - Properties
  
  @IBOutlet weak var imageV: UIImageView!
  //@IBOutlet weak var healthView: UIView!
  @IBOutlet weak var nameLbl: UILabel!
  @IBOutlet weak var countLabel: UILabel!
  //@IBOutlet weak var selectionBtn: UIButton!
  //@IBOutlet weak var deleteBtn: UIButton!
  
  public static let nibName         = "LensCVC"
  public static let reuseIdentifier = nibName
  
  weak var delegate: LensCVCDelegate?
  
  public var lens: Lens? {
    didSet {
      guard let l = lens else { return }
      
      if let i = l.thumbnail {
        imageV.image = i
      } else if let url = l.thumbnailURL {
        let url = URL(string: url)!
        imageV.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholderImage"))
        { (img, err, cach, url) in
          l.thumbnail = img
        }
      } else {
        imageV.image = UIImage(named: "placeholderImage")
      }

      
      nameLbl.text = lens?.title ?? ""
      
      let count = lens?.imageCount ?? 0      
      let imageString = count == 1 ? "image" : "images"
      countLabel.text = "\(count) \(imageString)"
      
    }
  }
  
  var isEditing: Bool = false {
    didSet {
      //deleteBtn.isHidden = !isEditing
    }
  }
  
  var isSelectedForTraining: Bool = false {
    didSet {
      //selectionBtn.isSelected = isSelectedForTraining
      //selectionBtn.backgroundColor = isSelectedForTraining ? Constants.AppBlue : UIColor(white: 0, alpha: 0.1)
    }
  }
  
  
  // MARK: - Object Lifecycle
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    //healthView.layer.cornerRadius = 4
    //selectionBtn.layer.cornerRadius = 11
  
    //layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
    //layer.borderWidth = 1
    
    let topColor = UIColor(white: 0, alpha: 0.60)
    delay(0.01) {
      self.imageV.addGradientLayer(frame: self.imageV.frame, colors: [topColor, .clear])
    }
    
  }
  
  
  // MARK: - Action Methods
  
  @IBAction func imageButtonPressed() {
    guard let l = lens else { return }
    
    delegate?.lensCVC(self, didSelectImage: l)
  }
  
  @IBAction func labelButtonPressed() {
    guard let l = lens else { return }
    
    delegate?.lensCVC(self, didSelectLens: l)
  }
  
  @IBAction func selectionButtonPressed(sender: UIButton) {
    sender.isSelected = !sender.isSelected
    
    guard let l = lens,
      let count = l.imageCount else { return }
    
    if sender.isSelected {
      if count < 35 {
        delegate?.lensCVCShouldShowLensCountAlert(self)
        sender.isSelected = false
        return
      }
      
      sender.backgroundColor = Constants.AppBlue
      delegate?.lensCVC(self, didSelectForTrain: l)
    } else {
      sender.backgroundColor = UIColor(white: 0, alpha: 0.1)
      delegate?.lensCVC(self, didDeSelectForTrain: l)
    }
    
  }

  @IBAction func deleteButtonPressed(sender: UIButton) {
    guard let l = lens else { return }
    delegate?.lensCVC(self, shouldDeleteLens: l)
  }
}
