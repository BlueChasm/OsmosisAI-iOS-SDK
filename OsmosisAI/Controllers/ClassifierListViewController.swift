//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import Dispatch
import SVProgressHUD
import UIKit

open class ClassifierListViewController: UIViewController {
  
  // MARK: - Properties
  
  @IBOutlet weak var tableV: UITableView!
  
  var classifiers = [Classifier]()
  
  lazy var refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    refreshControl.tintColor = Constants.AppBlue
    return refreshControl
  }()
  
  
  // MARK: - Object Lifecycle
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    let frameworkBundle = Bundle(for: ClassifierTVC.self)
    tableV.register(UINib(nibName: ClassifierTVC.nibName, bundle: frameworkBundle), forCellReuseIdentifier: ClassifierTVC.reuseIdentifier)
    tableV.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
    tableV.rowHeight = 60
    
    tableV.addSubview(refreshControl)
    
    refreshData()
  }

  
  // MARK: - Public Methods
  
  public class func setup() -> ClassifierListViewController {
    let frameworkBundle = Bundle(for: ClassifierListViewController.self)
    guard let viewController = UIStoryboard(name: "ClassifierListViewController", bundle: frameworkBundle).instantiateInitialViewController() as? ClassifierListViewController else {
      fatalError("Unable to instantiate ClassifierListViewController")
    }
    return viewController
  }
  
  
  // MARK: - Private Methods
  
  @objc func refreshData() {
    refreshControl.beginRefreshing()
    getClassifiers()
  }
  
  private func getClassifiers() {
    Classifier.getClassifiers { [weak self] (classifiers, error) in
      
      if let err = error {
        print(err)
        SVProgressHUD.dismiss()
        return
      }
      
      guard let cs = classifiers else {
        print("Unknown Error")
        SVProgressHUD.dismiss()
        return
      }
      
      self?.classifiers = cs
      
      self?.classifiers.sort (by: { (c1, c2) -> Bool in
        return c1.complete && !c2.complete
      })
      
      self?.processClassifiers()
    }
  }
  
  private func processClassifiers() {
    let group = DispatchGroup()
    
    for classifier in classifiers {
      group.enter()
    
      classifier.getClassifierResults { (classifier, error) in
        guard let c = classifier else {
          group.leave()
          return
        }
        
        if let _ = c.results {
          c.status = c.complete ? .deployed : .ready
        } else {
          c.status = .training
        }
        
        group.leave()
      }
      
    }

    group.notify(queue: DispatchQueue.global(qos: .userInteractive)) {
      DMQ {
        
        self.classifiers.sort(by: { $0.status.rawValue < $1.status.rawValue })
        
        self.tableV.reloadData()
        self.refreshControl.endRefreshing()
        SVProgressHUD.dismiss()
      }
    }
  }

  private func askToDeleteClassifier(classifier: Classifier) {
    let title = classifier.title ?? "this classifier"
    displayAlert(title: "Delete?", msg: "Are you sure want to delete \(title) ", ok: "YES", cancel: "NO", okAction: {
      self.deleteClassifier(classifier: classifier)
    }, cancelAction: nil)
  }
  
  private func deleteClassifier(classifier: Classifier) {
    SVProgressHUD.show()
    
    Classifier.deleteClassifier(classifier: classifier) { [weak self] (success, error) in
      if let err = error {
        SVProgressHUD.dismiss()
        self?.displayAlert(title: "Error", msg: err.localizedDescription, ok: "OK", cancel: nil, okAction: nil, cancelAction: nil)
        return
      }
      
      if classifier.complete {
        let graphPath = "\(classifier.id!)" + ".\(FileExtension.coreML.rawValue)"
        
        let filePath = "file://\(dataFolderPath())"
        if let subFolderPath = URL(string: filePath) {
          let graphResult = subFolderPath.appendingPathComponent(graphPath)

          do {
            try FileManager.default.removeItem(at: graphResult)

          } catch let error {
            print(error)
          }
        }
      }
      
      self?.getClassifiers()
    }
  }
}


// MARK: - UITableViewDataSource

extension ClassifierListViewController : UITableViewDataSource, UITableViewDelegate {
  
  private func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    let classifier = classifiers[indexPath.row]
    return !classifier.isBuiltIn
  }
  
  private func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let classifier = classifiers[indexPath.row]
      askToDeleteClassifier(classifier: classifier)
    }
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: ClassifierTVC.reuseIdentifier, for: indexPath) as! ClassifierTVC
    let classifier = classifiers[indexPath.row]
    cell.classifier = classifier
    
    cell.accessoryType = classifier.id == SessionData.shared.currentClassifier?.id ? .checkmark : .none
    
    cell.selectionStyle = classifier.complete ? .gray : .none
    
    cell.downloadComplete = { [weak self] in
      SessionData.shared.currentClassifier = classifier
      self?.tableV.reloadData()
    }
    
    return cell
  }
  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return classifiers.count
  }
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let classifier = classifiers[indexPath.row]
    
    if classifier.complete == false { return }
    
    SessionData.shared.currentClassifier = classifier
    
    tableView.reloadData()
  }
}
