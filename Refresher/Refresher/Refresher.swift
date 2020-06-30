//
//  RefrechControl.swift
//  Refresher
//
//  Created by Tomas Green on 2017-11-30.
//  Copyright © Tomas Green. All rights reserved.
//

import UIKit

fileprivate var refresherTag = -124951235

public extension UITableView {
    public func addRefresherWithAction(refreshStarted:(() -> Void)? = nil) {
        _ = Refresher(scrollView: self, refreshStarted: refreshStarted)
    }
    public func beginRefreshing(force:Bool = true) {
        guard let refresher = self.viewWithTag(refresherTag) as? Refresher else {
            return
        }
        refresher.beginRefreshing(force: force)
    }
    public func endRefreshing() {
        guard let refresher = self.viewWithTag(refresherTag) as? Refresher else {
            return
        }
        refresher.endRefreshing()
    }
    public var refresher:Refresher? {
        return self.viewWithTag(refresherTag) as? Refresher
    }
    public var isRefresing:Bool {
        guard let refresher = self.viewWithTag(refresherTag) as? Refresher else {
            return false
        }
        return refresher.isRefreshing
    }
}

@available(iOS 10.0, *) fileprivate var tapticFeedback = UISelectionFeedbackGenerator()

public class Refresher: UIView {
    public enum Style {
        case scrollView
        case navigationBar
    }
    private var scrollView:UIScrollView?
    private var viewController:UIViewController?
    private var titleView:UIView?
    private var activityIndicator:ActivityIndicator?
    private var capReached = false
    
    private(set) var isRefreshing = false
    
    public var style = Style.scrollView
    public var capHeight:CGFloat = 100
    public var height:CGFloat = 70
    public var indicatorSize: CGFloat = 38
    public var indicatorOffset = CGPoint(x: 10, y: 10)
    public var refreshStarted: (() -> Void)?
    public var refreshLabel:UILabel?
    public var pullToRefreshText = "Pull to refresh"
    public var releaseToRefreshText = "Release to refresh"
    public var activityIndicatorActiveBackgroundColor:UIColor = .clear
    public var usingVisualEffect:Bool = false {
        didSet {
            self.activityIndicatorActiveBackgroundColor = usingVisualEffect ? .clear : self.tintColor
        }
    }
    public var color:UIColor {
        get {
            return self.tintColor
        } set {
            self.tintColor = newValue
            self.refreshLabel?.textColor = newValue
            self.activityIndicator?.tintColor = newValue
            self.activityIndicatorActiveBackgroundColor = usingVisualEffect ? .clear : newValue
        }
    }
    public var navigationItemHeight:CGFloat {
        if #available(iOS 11.0, *) {
            return (viewController?.navigationItem.searchController?.searchBar.frame.size.height ?? 0) + indicatorOffset.y + (viewController?.navigationController?.navigationBar.frame.size.height ?? indicatorSize + indicatorOffset.y)
        } else {
            return indicatorOffset.y + (viewController?.navigationController?.navigationBar.frame.size.height ?? indicatorSize + indicatorOffset.y)
        }
    }
    public convenience init(scrollView:UIScrollView, refreshStarted:(() -> Void)? = nil) {
        self.init(frame: CGRect())
        self.refreshStarted = refreshStarted
        self.scrollView = scrollView
        activityIndicatorActiveBackgroundColor = .clear
        setup()
    }
    public convenience init(scrollView:UIScrollView, viewController:UIViewController? = nil,style:Style = .scrollView, refreshStarted:(() -> Void)? = nil) {
        self.init(frame: CGRect())
        self.refreshStarted = refreshStarted
        self.style = style
        
        if let color = viewController?.navigationController?.navigationBar.barTintColor {
            activityIndicatorActiveBackgroundColor = color
        }
        self.scrollView = scrollView
        self.viewController = viewController
        setup()
    }
    private func setup() {
        guard let scrollView = scrollView else {
            return
        }
        self.tag = refresherTag
        self.frame = CGRect(x: 0, y: self.height * -1, width: scrollView.frame.size.width, height: self.height)
        let refreshLabel = UILabel(frame: CGRect(x: 0, y: 40, width: bounds.width, height: bounds.height - 40))
        refreshLabel.textAlignment = .center
        refreshLabel.text = pullToRefreshText
        refreshLabel.font = UIFont.systemFont(ofSize: 13)
        
        let indicator = LineActivityIndicator(frame: CGRect(x: scrollView.frame.size.width - indicatorSize - indicatorOffset.x, y: self.indicatorOffset.y, width: indicatorSize, height: indicatorSize))
        indicator.layer.shadowColor = UIColor.black.cgColor
        indicator.layer.shadowOpacity = 0.2
        indicator.layer.shadowOffset = CGSize()
        indicator.layer.shadowRadius = 0
        indicator.layer.cornerRadius = indicator.frame.size.height/2
        self.backgroundColor = UIColor.clear
        
        self.activityIndicator = indicator
        self.refreshLabel = refreshLabel
        refreshLabel.isHidden = true
        
        scrollView.addSubview(indicator)
        scrollView.addSubview(self)
        scrollView.sendSubviewToBack(self)
        self.addSubview(refreshLabel)

        self.color = scrollView.tintColor
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
        scrollView.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
    }
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "contentOffset", let point = change?[NSKeyValueChangeKey.newKey] as? CGPoint {
            drag(offset: point)
        } else if keyPath == "frame", let rect = change?[NSKeyValueChangeKey.newKey] as? CGRect {
            self.frame.size.width = rect.width
            refreshLabel?.frame.size.width = rect.width
            if self.isRefreshing {
                let x = rect.size.width - indicatorSize - indicatorOffset.x
                activityIndicator?.frame.origin.x = x - rightOffset
            } else if let indicator = activityIndicator {
                indicator.frame.origin.x = (self.frame.width - indicator.frame.width)/2
            }
        }
    }
    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
        scrollView?.removeObserver(self, forKeyPath: "frame")
    }
    private var topOffset:CGFloat {
        if #available(iOS 11.0, *) {
            return viewController?.presentingViewController?.view.safeAreaInsets.top ?? 0
        }
        return 0
    }
    private var rightOffset:CGFloat {
        if #available(iOS 11.0, *) {
            return safeAreaInsets.right
        }
        return 0
    }
    private func drag(offset:CGPoint) {
        var scrollViewOffset = (offset.y * -1)
        if let margins = scrollView?.layoutMargins {
            scrollViewOffset -= margins.top
        }
        if isRefreshing == false {
            refreshLabel?.alpha =  scrollViewOffset/capHeight
        }
        let y = scrollViewOffset - self.frame.height
        if y > 0  {
            self.frame.origin.y = scrollViewOffset * -1
        } else {
            self.frame.origin.y = self.frame.size.height * -1
        }
        if isRefreshing == false, let indicator = self.activityIndicator {
            indicator.frame.origin.x = (self.frame.width - indicator.frame.width)/2
            indicator.frame.origin.y = self.frame.origin.y + (self.frame.height - indicator.frame.height)/2
            activityIndicator?.fadeFragments(offset: scrollViewOffset,maxHeight: capHeight)
        }
        activityIndicator?.frame.origin.y = self.indicatorOffset.y + scrollViewOffset * -1
    
        if scrollViewOffset > capHeight {
            if #available(iOS 10, *), isRefreshing == false && capReached == false {
                tapticFeedback.selectionChanged()
            }
            capReached = true
            if scrollView?.isDragging == false && isRefreshing == false {
                beginRefreshing()
            }
            if refreshLabel?.text != releaseToRefreshText {
                refreshLabel?.text = releaseToRefreshText
            }
        } else {
            capReached = false
            if refreshLabel?.text != pullToRefreshText {
                refreshLabel?.text = pullToRefreshText
            }
        }
    }
    public func beginRefreshing(force:Bool = false) {
        if isRefreshing {
            return
        }
        guard let scrollView = scrollView else {
            return
        }
        guard let indicator = activityIndicator else {
            return
        }
        if style == .scrollView {
            if force {
                indicator.frame.origin.x = scrollView.frame.size.width
            }
            if usingVisualEffect {
                indicator.effectView?.isHidden = false
            }
            indicator.backgroundColor = activityIndicatorActiveBackgroundColor
            indicator.color = UIColor.white
            UIView.animate(withDuration: 0.3, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIView.AnimationOptions(), animations: {
                self.refreshLabel?.alpha = 0
                indicator.layer.shadowRadius = 5
                indicator.frame.origin.x = scrollView.frame.size.width - self.indicatorSize - self.indicatorOffset.x - self.rightOffset
            }) { (done) in
                self.refreshStarted?()
            }
            indicator.startAnimating()
        } else if style == .navigationBar {
            indicator.alpha = 0
            let headerIndicator = LineActivityIndicator(frame: CGRect(x: 0, y: force ? 0 : navigationItemHeight, width: indicatorSize, height: indicatorSize))
            headerIndicator.tintColor = self.viewController?.navigationController?.navigationBar.tintColor
            self.titleView = self.viewController?.navigationItem.titleView
            viewController?.navigationItem.titleView = headerIndicator
            UIView.animate(withDuration: 0.3, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIView.AnimationOptions(), animations: {
                self.refreshLabel?.alpha = 0
                headerIndicator.frame.origin.y = 0
            }) { (done) in
                self.refreshStarted?()
            }
            headerIndicator.startAnimating()
        }
        isRefreshing = true
    }
    public func endRefreshing() {
        if isRefreshing == false {
            return
        }
        guard let scrollView = scrollView else {
            return
        }
        if style == .scrollView, let indicator = activityIndicator {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIView.AnimationOptions(), animations: {
                indicator.frame.origin.x = scrollView.frame.size.width
            }) { (done) in
                indicator.backgroundColor = UIColor.clear
                indicator.stopAnimating()
                self.isRefreshing = false
                indicator.color = self.tintColor
                indicator.layer.shadowRadius = 0
                if self.usingVisualEffect {
                    indicator.effectView?.isHidden = true
                }
            }
        } else if style == .navigationBar, let headerIndicator = viewController?.navigationItem.titleView as? ActivityIndicator {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIView.AnimationOptions(), animations: {
                headerIndicator.frame.origin.y = self.navigationItemHeight * -1
            }) { (done) in
                self.viewController?.navigationItem.titleView = self.titleView
                self.titleView = nil
                self.isRefreshing = false
            }
        }
        if #available(iOS 10, *) {
            tapticFeedback.selectionChanged()
        }
    }
}
