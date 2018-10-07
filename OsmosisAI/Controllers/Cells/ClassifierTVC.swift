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

public class ClassifierTVC: UITableViewCell {
  
  // MARK: - Properties
  
  @IBOutlet weak var nameL: UILabel!
  @IBOutlet weak var progressL: UILabel!
  @IBOutlet weak var imageV: UIImageView!
  @IBOutlet weak var downloadB: UIButton!
  @IBOutlet weak var indicator: UIActivityIndicatorView!
  @IBOutlet weak var progressIndicator: UIProgressView!
  
  public static let nibName         = "ClassifierTVC"
  public static let reuseIdentifier = nibName
  
  public var downloadComplete: (() -> Void)?
  
  public var classifier: Classifier? {
    didSet {
      guard let c = classifier else { return }
      
      nameL.text = c.title
      
      if let i = c.image {
        imageV.image = i
      } else if let urlString = c.imageURL {
        let url = URL(string: urlString)
        imageV.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholderImage"), options: SDWebImageOptions.refreshCached, progress: nil, completed: { (img, error, cacheType, url) in
          c.image = img
        })
      }
      
      if c.graphFileExists() {
        isUserInteractionEnabled = true
        progressL.textColor = Constants.AppBlue
        progressL.text = "Available"
        downloadB.isHidden = true
      } else {
        if let downloader = DownloadManager.shared.downloaderFromClassifier(classifier: c) {
          downloader.delegate = self
          setUIForDownload(download: true)
        } else {
          setUIForDownload(download: false)
        }
        
        if let _ = c.results {          
          isUserInteractionEnabled = true
          indicator.stopAnimating()
          
          if c.complete {
            progressL.textColor = Constants.AppBlue
            progressL.text = "Available"
            downloadB.isHidden = true
          } else {
            progressL.textColor = UIColor.darkGray
            progressL.text = "Ready for deployment"
            downloadB.isHidden = false
          }
        } else {
          progressIndicator.isHidden = true
          downloadB.isHidden = true
          isUserInteractionEnabled = false
          indicator.startAnimating()
          progressL.text = "Training..."
          progressL.textColor = UIColor.lightGray
        }
      }
    }
  }
  
  
  // MARK: - Object Lifecycle
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    downloadB.layer.borderColor = Constants.AppBlue.cgColor
    downloadB.layer.borderWidth = 1
  }
  
  
  // MARK: - Private Methods
  
  func setUIForDownload(download: Bool) {
    if download {
      downloadB.isUserInteractionEnabled = false
      downloadB.setTitle("DEPLOYING...", for: .normal)
      downloadB.alpha = 0.5
    } else {
      progressIndicator.isHidden = true
      downloadB.isUserInteractionEnabled = true
      downloadB.setTitle("DEPLOY", for: .normal)
      downloadB.alpha = 1
    }
  }
  
  
  // MARK: - Action Methods
  
  @IBAction func downloadButtonPressed() {
    
    guard let c = classifier else { return }
    
    let downloader = DownloadManager.shared.downloadClassifierFiles(classifier: c)
    downloader?.delegate = self
    
    setUIForDownload(download: true)
    
  }
}


// MARK: - DownloaderDelegate

extension ClassifierTVC : DownloaderDelegate {
  public func downloader(_ downloader: Downloader, didFail classifierID: Int, withError error: NSError) {
    guard let id = classifier?.id,
      id == classifierID else { return }
    
    DownloadManager.shared.removeDownloader(downloader: downloader)
    
    setUIForDownload(download: false)
    progressL.textColor = UIColor.darkGray
    progressL.text = "Ready for deployment"
    downloadB.isHidden = false
  }
  
  public func downloader(_ downloader: Downloader, didComplete classifierID: Int) {
    guard let id = classifier?.id,
      id == classifierID else { return }
    
    DownloadManager.shared.removeDownloader(downloader: downloader)
    
    setUIForDownload(download: false)
    progressL.textColor = Constants.AppBlue
    progressL.text = "Available"
    downloadB.isHidden = true
    isUserInteractionEnabled = true
    
    downloadComplete?()
  }
  
  public func downloader(_ downloader: Downloader, didUpdateProgress classifierID: Int, progress: Double) {
    guard let id = classifier?.id,
      id == classifierID else { return }
    
    progressIndicator.isHidden = false
    progressIndicator.progress = Float(progress)
  }
  
  
}
