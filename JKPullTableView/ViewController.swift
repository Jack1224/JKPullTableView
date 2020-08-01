//
//  ViewController.swift
//  JKPullTableView
//
//  Created by Jaki.W on 2020/8/1.
//  Copyright © 2020 Jaki.W. All rights reserved.
//

import UIKit

let kBottomClosedHeight : CGFloat = 204 - 34
let kBottomPartiallyExpandHeight : CGFloat = UIScreen.main.bounds.height - 336.0
let kBottomExpand :CGFloat = 0

class ViewController: UIViewController {

    
    lazy var pullerController: JKPulleyViewController = {
        let vc = JKPulleyViewController()
        return vc
    }()
    lazy var topController: JKTopViewController = {
        let vc = JKTopViewController()
        return vc
    }()
    
    lazy var bottomController: JKBottomViewController = {
        let vc = JKBottomViewController()
        return vc
    }()
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false;
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pullerController = JKPulleyViewController.init(contentDataSource: topController, drawerDataSource: bottomController)
        pullerController.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        pullerController.drawerExpandTopInset = 64
        pullerController.drawerDelegate = self.bottomController
        pullerController.supportedStatus = [.closed, .expand]
        pullerController.dimmingOpacity = 0.2
        pullerController.addChild(topController)
        pullerController.addChild(bottomController)
        self.addChild(pullerController)
        self.view.addSubview(pullerController.view)
        pullerController.update(status: .closed, animated: false)
    }


}

