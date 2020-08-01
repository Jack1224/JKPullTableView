//
//  JKPulleyViewController.swift
//  JKPullTableView
//
//  Created by Jaki.W on 2020/8/1.
//  Copyright © 2020 Jaki.W. All rights reserved.
//

import UIKit

struct JKPulleyStatus : OptionSet {
    let rawValue: UInt
    static let none =  JKPulleyStatus(rawValue: 1 << 0) // 不在可视范围
    static let closed =  JKPulleyStatus(rawValue: 1 << 1) // 收起
    static let partiallyExpand =  JKPulleyStatus(rawValue: 1 << 2) // 部分展开
    static let expand =  JKPulleyStatus(rawValue: 1 << 3) //全部展开
    
}
/// 主内容视图数据源协议
@objc protocol JKPulleyContentDataSource {
    /// 主内容试图
    func mainView() -> UIView
    
}

/// 抽屉视图数据源协议
@objc protocol JKPulleyDrawerDataSource {
    
    /// 抽屉视图
    func mainView() -> UIView
    
    /// 关闭状态的高度
    func closedHeightIn(pulleyViewController:JKPulleyViewController) -> CGFloat
    /// 部分展开状态的高度
    func partiallyExpandHeightIn(pulleyViewController:JKPulleyViewController) -> CGFloat
    /// 全部展开状态的高度
    func expandHeightIn(pulleyViewController:JKPulleyViewController) -> CGFloat
    
}

protocol JKPulleyDrawerDelegate : NSObjectProtocol{
    
    /**
     当抽屉视图状态改变时回调

     @param pulleyViewController pulleyViewController
     @param status 改变后的状态，该状态是唯一的，不存在位移
     */
    func pulleyDrawer(pulleyViewController:JKPulleyViewController, didChangeStatus:JKPulleyStatus)
        
    /**
     实时回调抽屉视图的滚动进度

     @param pulleyViewController pulleyViewController
     @param progress 滚动进度：0 - 1
     */
    func pulleyDrawer(pulleyViewController:JKPulleyViewController, drawerDraggingProgress:CGFloat)
 
}

@objc protocol JKPulleyDrawerScrollViewDelegate {
    
    /// 抽屉视图中的 scrollView 的 offset 改变时
    func drawerScrollViewDidScroll(scrollView:UIScrollView)
    
}


class JKPulleyViewController: UIViewController {
    
    weak var contentDataSource:JKPulleyContentDataSource?
    weak var drawerDataSource:JKPulleyDrawerDataSource?
    weak var drawerDelegate:JKPulleyDrawerDelegate?
    
    /**
    抽屉视图关闭状态高度
    当 drawerDataSource 没有实现 closedHeightInPulleyViewController 时使用该值
    默认：68
    */
    var drawerClosedHeight : CGFloat {
        get
        {
            if let drawerDataSource = self.drawerDataSource
            {
               return drawerDataSource.closedHeightIn(pulleyViewController: self)
            }
            else
            {
                return 68
            }
        }
    }
    
    
    /**
    抽屉视图部分展开状态高度
    当 drawerDataSource 没有实现 partiallyExpandHeightInPulleyViewController 时使用该值
    默认：264
    */
    var drawerPartiallyExpandHeight : CGFloat {
        get
        {
            if let drawerDataSource = self.drawerDataSource
            {
               return drawerDataSource.partiallyExpandHeightIn(pulleyViewController: self)
            }
            else
            {
                return 264
            }
        }
    }
    
    /**
     抽屉视图全部展开状态高度
     默认: 全屏
     */
    var drawerExpandHeight : CGFloat {
        get
        {
            if let drawerDataSource = self.drawerDataSource
            {
               return drawerDataSource.expandHeightIn(pulleyViewController: self)
            }
            else
            {
                return 0
            }
        }
    }
    /// 抽屉视图全展开状态顶部内边距，默认：20
    lazy var drawerExpandTopInset : CGFloat = 20
    
    //当前状态
    var currentStatus : JKPulleyStatus!{
        didSet {
            if let drawerDelegate = self.drawerDelegate
            {
                drawerDelegate.pulleyDrawer(pulleyViewController: self, didChangeStatus: currentStatus)
            }
        }
    }
    
    // 支持的状态
    var supportedStatus : JKPulleyStatus =  [.closed, .partiallyExpand, .expand]
    
    /**
    背景遮罩，默认为一个普通的 UIView，背景色为 blackColor，可设置为自己的 view
    注意：dimmingView 的大小将会盖满整个控件
    JYPulleyViewController 会自动给自定义的 dimmingView 添加手势以实现点击遮罩隐藏浮层
    */
    lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.alpha = dimmingOpacity
        return view
    }()
    /// 背景遮罩点击手势
    lazy var dimmingViewTapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didRecognizedDimmingViewTapGestureRecognizer(_ :)))
        return tap
    }()
    
    /// 背景遮罩显示时的不透明度，默认：0.5
    lazy var dimmingOpacity:CGFloat = 0.5
    
    /// 记录最后一次滑动位置
    lazy var lastContentOffSet : CGPoint = CGPoint(x: 0, y: 0)
    
    /// 抽屉视图是否可以滚动
    lazy var drawerShouldScroll : Bool = false
    
    lazy var drawerContainerView: UIView = {
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var contentContainerView: UIView = {
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var scrollViewPanGestureRecognizer: UIPanGestureRecognizer = {
        let scrollViewPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didRecognizedScrollViewPanGestureRecognizer(_ :)))
        scrollViewPanGestureRecognizer.delegate = self
        return scrollViewPanGestureRecognizer
    }()
    

    
    lazy var scrollView: JKPulleyScrollView = {
        let scrollView = JKPulleyScrollView(frame: self.drawerContainerView.bounds)
        scrollView.backgroundColor = UIColor.clear
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false;
        scrollView.showsHorizontalScrollIndicator = false;
        scrollView.bounces = false;
        scrollView.canCancelContentTouches = true;
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast;
        scrollView.touchDelegate = self;
        scrollView.addGestureRecognizer(scrollViewPanGestureRecognizer)
        return scrollView
    }()
    
    
    init(contentDataSource:JKPulleyContentDataSource, drawerDataSource:JKPulleyDrawerDataSource)
    {
       super.init(nibName: nil, bundle: nil)
        self.contentDataSource = contentDataSource;
        self.drawerDataSource = drawerDataSource;

    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    }
    required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
       override func viewDidLoad() {
           super.viewDidLoad()

           configBasic()
           loadSubview()
           
       }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        contentContainerView.addSubview(contentDataSource!.mainView())
        contentContainerView.sendSubviewToBack(contentDataSource!.mainView())
        
        drawerContainerView.addSubview(drawerDataSource!.mainView())
        drawerContainerView.sendSubviewToBack(drawerDataSource!.mainView())
        
        contentContainerView.frame = self.view.bounds
        
        var safeAreaTopInset:CGFloat
        var safeAreaBottomInset:CGFloat
        if #available(iOS 11.0, *)
        {
            safeAreaTopInset = self.view.safeAreaInsets.top
            safeAreaBottomInset = self.view.safeAreaInsets.bottom
        }
        else
        {
            safeAreaTopInset = self.topLayoutGuide.length
            safeAreaBottomInset = self.bottomLayoutGuide.length
        }
        if #available(iOS 11.0, *)
        {
            scrollView.contentInsetAdjustmentBehavior = .always
        }
        else
        {
            self.automaticallyAdjustsScrollViewInsets = false;
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.bottomLayoutGuide.length, right: 0)
        }
        
        let minimumHeight = drawerClosedHeight
        
        
        if self.supportedStatus.contains(.expand)
        {
            scrollView.frame = CGRect(x: 0, y: drawerExpandTopInset + safeAreaTopInset, width: self.view.bounds.size.width, height: self.view.bounds.size.height - drawerExpandTopInset - safeAreaTopInset)
        }
        else
        {
            let adjustedTopInset = self.supportedStatus.contains(.partiallyExpand) ? drawerPartiallyExpandHeight : drawerClosedHeight
            scrollView.frame = CGRect(x: 0, y: self.view.bounds.size.height - adjustedTopInset, width: self.view.bounds.size.width, height: adjustedTopInset)
        }
        
        
        self.drawerContainerView.frame = CGRect(x: 0, y: scrollView.bounds.size.height - minimumHeight, width: self.scrollView.bounds.size.width, height: self.scrollView.bounds.size.height)

        self.scrollView.contentSize = CGSize(width: self.scrollView.bounds.size.width, height: (self.scrollView.bounds.size.height - minimumHeight) +
        self.scrollView.bounds.size.height - safeAreaBottomInset)
        self.dimmingView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.scrollView.contentSize.height)
        update(status: currentStatus, animated: false)
        
    }

}

extension JKPulleyViewController {
    
    private func configBasic() {
        navigationController?.navigationBar.isHidden = true;
        self.view.backgroundColor = UIColor.green
        self.lastContentOffSet = CGPoint.zero;
        
    }
    
    private func loadSubview() {
        scrollView.addSubview(drawerContainerView)
        view.addSubview(contentContainerView)
        view.addSubview(scrollView)
        setupDimmingView()
    }
    
    private func setupDimmingView() {
        self.dimmingView.alpha = 0.0;
        addTapGestureRecognizerToDimmingViewIfNeeded()
        self.view.insertSubview(dimmingView, aboveSubview: contentContainerView)
    }
}

extension JKPulleyViewController {
    
    /**
    根据伸缩状态处理悬停动作

    @param status 伸缩状态
    */
    func update(status:JKPulleyStatus, animated:Bool) {
        
        let stopToMoveTo:CGFloat
        let minimumHeight = drawerClosedHeight
        
        if status.contains(.closed)
        {
            stopToMoveTo = minimumHeight
        }
        else if status.contains(.partiallyExpand)
        {
            stopToMoveTo = drawerPartiallyExpandHeight
        }
        else if status.contains(.expand)
        {
            if drawerExpandHeight > 0.0
            {
                stopToMoveTo = drawerExpandHeight
            }
            else
            {
                stopToMoveTo = scrollView.frame.size.height
            }
        }
        else
        {
            stopToMoveTo = 0.0
        }
        self.currentStatus = status;
        if animated
        {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: stopToMoveTo - minimumHeight), animated: false)
                self.dimmingView.frame = self.dimmingViewFrameForDrawer(position: stopToMoveTo)
            }, completion: nil)
        }
        else
        {
            scrollView.setContentOffset(CGPoint(x: 0, y: stopToMoveTo - minimumHeight), animated: false)
            self.dimmingView.frame = self.dimmingViewFrameForDrawer(position: stopToMoveTo)

        }
    }
    
    @objc func didRecognizedScrollViewPanGestureRecognizer(_ gestureRecognizer:UIPanGestureRecognizer) {
        if !drawerShouldScroll
        {
            return;
        }

        if gestureRecognizer.state == .changed
        {
            let old = gestureRecognizer.translation(in: scrollView)

            if old.x < 0
            {
                return
            }

            let offSet = CGPoint(x:0 , y: scrollView.frame.size.height - old.y - drawerClosedHeight)
            lastContentOffSet = offSet
            scrollView.contentOffset = offSet
        }
        else if gestureRecognizer.state == .ended
        {
            drawerShouldScroll = false
            let status = newStatusFrom(currentStatus: currentStatus, lastContentOffSet: lastContentOffSet, scrollView: scrollView, supportedStatus: supportedStatus)

            update(status: status, animated: true)
        }
    }
    
    @objc func didRecognizedDimmingViewTapGestureRecognizer(_ gestureRecognizer:UITapGestureRecognizer){
        
        if (gestureRecognizer.state == .ended)
        {
            update(status: .closed, animated: true)
        }
        
    }
    
    private func newStatusFrom(currentStatus:JKPulleyStatus,
                                   lastContentOffSet:CGPoint,
                                   scrollView:UIScrollView,
                              supportedStatus:JKPulleyStatus) -> JKPulleyStatus {
            
            var drawerStops : [CGFloat] = NSMutableArray() as! [CGFloat]
            
            
            if supportedStatus.contains(.closed)
            {
                let collapsedHeight = drawerClosedHeight
                drawerStops.append(collapsedHeight)
            }
            if supportedStatus.contains(.partiallyExpand)
            {
                let partialHeight = drawerPartiallyExpandHeight
                drawerStops.append(partialHeight)
            }
            if  supportedStatus.contains(.expand)
            {
                let openHeight = scrollView.bounds.size.height
                drawerStops.append(openHeight)
            }
            
            let lowestStop = drawerStops.min()
            let distanceFromBottomOfView = lowestStop! + lastContentOffSet.y
            var currentClosestStop = lowestStop!
            
            var cloestValidDrawerStatus = currentStatus
            
            for currentStop in drawerStops
            {
                
                if fabsf(Float(currentStop - distanceFromBottomOfView)) < fabsf(Float(currentClosestStop - distanceFromBottomOfView))
                {
                    currentClosestStop = currentStop
                }
                
            }
            
            if fabsf(Float(currentClosestStop - (scrollView.frame.size.height))) <= Float.ulpOfOne && supportedStatus.contains(.expand)
            {
                cloestValidDrawerStatus = .expand
            }
            else if fabsf(Float(currentClosestStop - self.drawerClosedHeight)) <= Float.ulpOfOne && supportedStatus.contains(.closed)
            {
                cloestValidDrawerStatus = .closed
            }
            else if supportedStatus.contains(.partiallyExpand)
            {
                cloestValidDrawerStatus = .partiallyExpand
            }
            
            return cloestValidDrawerStatus

        }
    
    private func updateDrawerDraggingProgress(scrollView:UIScrollView){
            
            let  drawerClosedHeightA = drawerClosedHeight
            
            var  safeAreaTopInset : CGFloat
            
            if #available(iOS 11.0, *)
            {
                safeAreaTopInset = self.view.safeAreaInsets.top
            }
            else
            {
                safeAreaTopInset = self.topLayoutGuide.length
                
            }
            
            let spaceToDrag = self.scrollView.bounds.size.height - safeAreaTopInset - drawerClosedHeightA
        
            var dragProgress = abs(scrollView.contentOffset.y) / spaceToDrag
            
            if (dragProgress - 1.0) > CGFloat(Float.ulpOfOne)
            {
                dragProgress = 1.0
            }
            
            let progress : String = String(format: "0.2f", dragProgress)
            
            if let drawerDelegate = self.drawerDelegate
            {
                drawerDelegate.pulleyDrawer(pulleyViewController: self, drawerDraggingProgress: CGFloat(Double(progress) ?? 0))
            }
        }
    
    private func updateDimmingViewAlpha(scrollView:UIScrollView){
        
        var safeAreaBottomInset : CGFloat
        let drawerClosedHeight = self.drawerClosedHeight
        
        if  #available(iOS 11.0, *)
        {
            safeAreaBottomInset = self.view.safeAreaInsets.bottom
        }
        else
        {
            safeAreaBottomInset = self.bottomLayoutGuide.length
        }
        
        // 背景遮罩颜色变化
        
        if (scrollView.contentOffset.y - safeAreaBottomInset) > (drawerPartiallyExpandHeight - drawerClosedHeight)
        {
            var progress : CGFloat
            let fullRevealHeight : CGFloat = self.scrollView.bounds.size.height
            if fullRevealHeight == self.drawerPartiallyExpandHeight
            {
                progress = 1.0
            }
            else
            {
                progress = (scrollView.contentOffset.y - (self.drawerPartiallyExpandHeight - drawerClosedHeight)) / (fullRevealHeight - self.drawerPartiallyExpandHeight)
            }
            
            self.dimmingView.alpha = progress * self.dimmingOpacity
            self.dimmingView.isUserInteractionEnabled = true
        }
        else
        {
            if self.dimmingView.alpha >= 0.01
            {
                self.dimmingView.alpha = 0.0
                self.dimmingView.isUserInteractionEnabled = false
            }
        }
        
        self.dimmingView.frame = self.dimmingViewFrameForDrawer(position: (scrollView.contentOffset.y + drawerClosedHeight))
    }
    
    private func addTapGestureRecognizerToDimmingViewIfNeeded() {
        
        self.dimmingView.addGestureRecognizer(self.dimmingViewTapGestureRecognizer)
        
        self.dimmingView.isUserInteractionEnabled = true
    }

    private func dimmingViewFrameForDrawer(position:CGFloat) -> CGRect
    {
        var  dimmingViewFrame : CGRect = dimmingView.frame
        dimmingViewFrame.origin.y = 0 - position
        
        return dimmingViewFrame
    }
    
    
}

extension JKPulleyViewController : JKPulleyScrollViewDelegate, UIScrollViewDelegate {
    
    func shouldTouchPulleyScrollView(scrollView:JKPulleyScrollView, point:CGPoint) -> Bool {
        
        let convertPoint = self.drawerContainerView.convert(point, from: scrollView)
        
        return !self.drawerContainerView.bounds.contains(convertPoint)
    }
    
    func viewToReceiveTouch(scrollView:JKPulleyScrollView, point:CGPoint) -> UIView {
        
        if self.currentStatus.contains(.expand)
        {
            return self.dimmingView
        }

        return self.contentContainerView;
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != self.scrollView
        {
            return
        }
        updateDrawerDraggingProgress(scrollView: scrollView)
        updateDimmingViewAlpha(scrollView:scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView != self.scrollView
        {
            return
        }
        
        let newStatus = newStatusFrom(currentStatus: currentStatus, lastContentOffSet: lastContentOffSet, scrollView: scrollView, supportedStatus: supportedStatus)
        update(status: newStatus, animated: true)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView != self.scrollView
        {
            return
        }
        lastContentOffSet = CGPoint(x: targetContentOffset.pointee.x, y: targetContentOffset.pointee.y)
    }
}

extension JKPulleyViewController : UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool{
        return true
    }
    
}

extension JKPulleyViewController : JKPulleyDrawerScrollViewDelegate {
    
    func drawerScrollViewDidScroll(scrollView:UIScrollView) {
        if (scrollView.contentOffset.y <= 0) {
            drawerShouldScroll = true
            scrollView.isScrollEnabled = false
        } else {
            drawerShouldScroll = false
            scrollView.isScrollEnabled = true;
        }
    }
}


