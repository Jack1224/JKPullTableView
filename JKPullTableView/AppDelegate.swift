//
//  AppDelegate.swift
//  JKPullTableView
//
//  Created by Jaki.W on 2020/8/1.
//  Copyright © 2020 Jaki.W. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

     var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.makeKeyAndVisible()
        self.window!.rootViewController = ViewController()
        return true
    }




}

