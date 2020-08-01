//
//  JKPulleyScrollView.swift
//  JKPullTableView
//
//  Created by Jaki.W on 2020/8/1.
//  Copyright © 2020 Jaki.W. All rights reserved.
//

import UIKit

@objc protocol JKPulleyScrollViewDelegate {
    func shouldTouchPulleyScrollView(scrollView:JKPulleyScrollView, point:CGPoint) -> Bool
    
    func viewToReceiveTouch(scrollView:JKPulleyScrollView, point:CGPoint) -> UIView
}

class JKPulleyScrollView: UIScrollView {

   weak var touchDelegate: JKPulleyScrollViewDelegate?
   
   override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
       
       if self.touchDelegate?.shouldTouchPulleyScrollView(scrollView: self, point: point) ?? false
       {
           let view = self.touchDelegate?.viewToReceiveTouch(scrollView: self, point: point)
           let po = view?.convert(point, from: self) ?? CGPoint.zero
           return view?.hitTest(po, with: event)
       }
       
       return super.hitTest(point, with: event)
   }
   
   override func touchesShouldCancel(in view: UIView) -> Bool {
       
       if view.isKind(of: UIButton.self)
       {
           return true
       }
       else
       {
           return super.touchesShouldCancel(in: view)
       }
   }

}
