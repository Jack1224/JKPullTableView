//
//  JKBottomViewController.swift
//  JKPullTableView
//
//  Created by Jaki.W on 2020/8/1.
//  Copyright © 2020 Jaki.W. All rights reserved.
//

import UIKit

class JKBottomViewController: UIViewController {
    
    weak var  drawerScrollDelegate:JKPulleyDrawerScrollViewDelegate?
    
    lazy var tableView: UITableView = {

        let tableViewLazy = UITableView(frame: self.view.bounds, style: .plain)
        tableViewLazy.delegate = self
        tableViewLazy.dataSource = self
        
        self.view.addSubview(tableViewLazy)
        return tableViewLazy
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }


}

extension JKBottomViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
         return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "cellId"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if !(cell != nil)
        {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
        }
        
        cell!.textLabel!.text = String(format: "==%ld==", indexPath.row)
        cell!.textLabel?.textAlignment = .center
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension JKBottomViewController : JKPulleyDrawerDataSource {
    

    func mainView() -> UIView {
        return self.view
    }
    
    func closedHeightIn(pulleyViewController: JKPulleyViewController) -> CGFloat {
        return kBottomClosedHeight
    }
    func partiallyExpandHeightIn(pulleyViewController: JKPulleyViewController) -> CGFloat {
        return kBottomPartiallyExpandHeight
    }
    func expandHeightIn(pulleyViewController: JKPulleyViewController) -> CGFloat {
        return kBottomExpand
    }
    
    
    
    
}
extension JKBottomViewController : JKPulleyDrawerDelegate {
    
    
    
    func pulleyDrawer(pulleyViewController: JKPulleyViewController, drawerDraggingProgress: CGFloat) {
        
    }
    
    func pulleyDrawer(pulleyViewController:JKPulleyViewController, didChangeStatus:JKPulleyStatus) {
        
        if didChangeStatus.contains(.closed)
        {
            
            self.tableView.isScrollEnabled = false

        }
        else if didChangeStatus.contains(.partiallyExpand)
        {
            self.tableView.isScrollEnabled = false

        }
        else if didChangeStatus.contains(.expand)
        {
            self.tableView.isScrollEnabled = true

        }
    }
}

