//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import UIKit

open class LensListViewController: UIViewController {
  
  // MARK: - Properties
  
  @IBOutlet weak var collectionV: UICollectionView!
  
  var lenses = [Lens]()
  
  lazy var refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    refreshControl.tintColor = Constants.AppBlue
    return refreshControl
  }()
  
  
  // MARK: - Object Lifecycle
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    let frameworkBundle = Bundle(for: LensCVC.self)
    collectionV.register(UINib(nibName: LensCVC.nibName, bundle: frameworkBundle), forCellWithReuseIdentifier:  LensCVC.reuseIdentifier)
    collectionV.contentInset = UIEdgeInsets(top: 80, left: 0, bottom: 0, right: 0)
    
    print(view.frame.size)
    let cellWidth : CGFloat = (view.frame.size.width / 2) - 16
    //let cellheight : CGFloat = view.frame.size.width / 2
    let cellSize = CGSize(width: cellWidth , height: cellWidth)
    
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.itemSize = cellSize
    layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    layout.minimumLineSpacing = 10.0
    layout.minimumInteritemSpacing = 1.0
    collectionV.setCollectionViewLayout(layout, animated: true)
    
    collectionV.addSubview(refreshControl)
    refreshData()
  }
  
  
  // MARK: - Public Methods
  
  public class func setup() -> LensListViewController {
    let frameworkBundle = Bundle(for: LensListViewController.self)
    guard let viewController = UIStoryboard(name: "LensListViewController", bundle: frameworkBundle).instantiateInitialViewController() as? LensListViewController else {
      fatalError("Unable to instantiate LensListViewController")
    }
    return viewController
  }
  
  
  // MARK: - Private Methods
  
  @objc func refreshData() {
    refreshControl.beginRefreshing()
    getLenses()
  }
  
  private func getLenses() {
    Lens.getLenses { [weak self] (lenses, error) in
      if let err = error {
        print(err)
        // RTV: TODO - Handle error
        self?.refreshControl.endRefreshing()
        return
      }
      
      guard let l = lenses else {
        // RTV: TODO - Handle error
        self?.refreshControl.endRefreshing()
        return
      }
      
      self?.lenses = l.sorted(by: {$0.id < $1.id})
      
      self?.refreshControl.endRefreshing()
      
      UIView.performWithoutAnimation {
        self?.collectionV.reloadSections(IndexSet(integer: 0))
      }
    }
  }
  
}


// MARK: - UICollectionViewDataSource

extension LensListViewController : UICollectionViewDataSource {
  
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LensCVC.reuseIdentifier, for: indexPath) as! LensCVC
    
    let lens = lenses[indexPath.item]
    cell.lens = lens
    //cell.delegate = self
    //cell.isEditing = isDeleting
    //cell.isSelectedForTraining = trainingSets.contains(where: {$0.id == lens.id})
    
    return cell
  }
  
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return lenses.count
  }
  
}
