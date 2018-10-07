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
  import CoreML
  import Foundation
  
  public protocol DownloaderDelegate: class {
    func downloader(_ downloader: Downloader, didFail classifierID: Int, withError error: NSError)
    func downloader(_ downloader: Downloader, didComplete classifierID: Int)
    func downloader(_ downloader: Downloader, didUpdateProgress classifierID: Int, progress: Double)
  }
  
  public class Downloader {
    
    public  var classifier: Classifier!
    
    public weak var delegate: DownloaderDelegate?
    
    init(classifier: Classifier) {
      self.classifier = classifier
    }
    
    public func downloadClassifier() {
      guard let id = classifier.id else { return }
      
      let fileManager = FileManager.default
      
      let graphPath = "\(id)" + "." + "mlmodel"
      let compiledGraphPath = "\(id)" + ".\(FileExtension.coreML.rawValue)"
      let labelsPath = "\(id)" + ".\(FileExtension.text.rawValue)"
      
      let filePath = "file://\(dataFolderPath())"
      
      guard let subFolderPath = URL(string: filePath) else { return }
      
      let graphResult = subFolderPath.appendingPathComponent(graphPath)
      let compiledGraphResult = subFolderPath.appendingPathComponent(compiledGraphPath)
      let labelsResult = subFolderPath.appendingPathComponent(labelsPath)
      
      do {
        try fileManager.createDirectory(atPath: subFolderPath.path, withIntermediateDirectories: true, attributes: nil)
        
        guard (subFolderPath as NSURL).checkResourceIsReachableAndReturnError(nil) else {
          let error = NSError(domain: "DownloadError", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Unknown Error with folder"])
          delegate?.downloader(self, didFail: id, withError: error)
          return
        }
        
        guard let graphURLString = classifier.results?.graph,
          let labelsURLString = classifier.results?.labels else {
            let error = NSError(domain: "DownloadError", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Unknown Error with coreML URL"])
            delegate?.downloader(self, didFail: id, withError: error)
            return
        }
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
          return (graphResult, [.createIntermediateDirectories, .removePreviousFile])
        }
        
        Alamofire.download(graphURLString, method: .get, parameters: nil, encoding: JSONEncoding.default, to: destination).responseJSON { [weak self] response in
          guard let `self` = self else { return }
          
          guard let url = response.destinationURL else {
            let error = NSError(domain: "DownloadError", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Invalid coreML URL"])
            self.delegate?.downloader(self, didFail: id, withError: error)
            return
          }
          
          guard let compiledModelURL = try? MLModel.compileModel(at: url) else {
            let error = NSError(domain: "DownloadError", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Can't compile CoreML model"])
            self.delegate?.downloader(self, didFail: id, withError: error)
            return
          }
          
          do {
            if fileManager.fileExists(atPath: compiledGraphResult.absoluteString) {
              _ = try fileManager.replaceItemAt(compiledGraphResult, withItemAt: compiledModelURL)
            } else {
              try fileManager.copyItem(at: compiledModelURL, to: compiledGraphResult)
            }
            
            self.classifier.graphFileURL = compiledGraphResult
          } catch {
            let error = NSError(domain: "DownloadError", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Error during copy: \(error.localizedDescription)"])
            self.delegate?.downloader(self, didFail: id, withError: error)
            return
          }
          
          let labelsDestination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (labelsResult, [.createIntermediateDirectories, .removePreviousFile])
          }
          
          Alamofire.download(labelsURLString, method: .get, parameters: nil, encoding: JSONEncoding.default, to: labelsDestination).responseJSON { [weak self] response in
            guard let `self` = self else { return }
            
            self.classifier.labelsFileURL = response.destinationURL
            
            self.classifier.complete = true
            
            NotificationCenter.default.post(name: Constants.ClassifierDownloadComplete, object: nil, userInfo: nil)
            self.delegate?.downloader(self, didComplete: id)
            
            }.downloadProgress(closure: { progress in
            })
          }.downloadProgress(closure: { [weak self] progress in
            guard let `self` = self else { return }
            
            self.delegate?.downloader(self, didUpdateProgress: id, progress: progress.fractionCompleted)
          })
      } catch let error {
        print(error)
        delegate?.downloader(self, didFail: id, withError: error as NSError)
      }
    }
  }
