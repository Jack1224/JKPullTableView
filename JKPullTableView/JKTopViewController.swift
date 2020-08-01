//
//  JKTopViewController.swift
//  JKPullTableView
//
//  Created by Jaki.W on 2020/8/1.
//  Copyright © 2020 Jaki.W. All rights reserved.
//

import UIKit

class JKTopViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.red
    }
    

    
    

}

extension JKTopViewController : JKPulleyContentDataSource {
    
    @objc func mainView() -> UIView {
        return self.view
    }
    
    
}
