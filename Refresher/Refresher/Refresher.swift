//
//  RefrechControl.swift
//  Refresher
//
//  Created by Tomas Green on 2017-11-30.
//  Copyright © Tomas Green. All rights reserved.
//

import UIKit

public class Refresher: UIView {
    public enum Style {
        case scrollView
        case navigationBar
    }
    private var scrollView:UIScrollView?
    private var viewController:UIViewController?
    private var titleView:UIView?
    private var activityIndicator:ActivityIndicator?
    private var tapticFeedback = UISelectionFeedbackGenerator()
    private var capReached = false
    
    private(set) var isRefreshing = false
    
    public var style = Style.scrollView
    public var capHeight:CGFloat = 100
    public var height:CGFloat = 70
    public var indicatorSize: CGFloat = 38
    public var indicatorOffset = CGPoint(x: 10, y: 10)
    public var didPullDown: (() -> Void)?
    public var refreshLabel:UILabel?
    public var pullToRefreshText = "Pull to refresh"
    public var releaseToRefreshText = "Release to refresh"
    public var activityIndicatorActiveBackgroundColor = UIColor.white

    public var color:UIColor {
        get {
            return self.tintColor
        } set {
            self.tintColor = newValue
            self.refreshLabel?.textColor = newValue
            self.activityIndicator?.tintColor = newValue
        }
    }
    public var navigationItemHeight:CGFloat {
        return indicatorOffset.y + (viewController?.navigationController?.navigationBar.frame.size.height ?? indicatorSize + indicatorOffset.y)
    }
    public convenience init(scrollView:UIScrollView, viewController:UIViewController? = nil,style:Style = .scrollView) {
        self.init(frame: CGRect())
        self.style = style
        self.frame = CGRect(x: 0, y: self.height * -1, width: scrollView.frame.size.width, height: self.height)
        let refreshLabel = UILabel(frame: CGRect(x: 0, y: 40, width: bounds.width, height: bounds.height - 40))
        refreshLabel.textAlignment = .center
        refreshLabel.text = pullToRefreshText
        refreshLabel.font = UIFont.systemFont(ofSize: 13)

        let indicator = LineActivityIndicator(frame: CGRect(x: scrollView.frame.size.width - indicatorSize - indicatorOffset.x, y: self.indicatorOffset.y, width: indicatorSize, height: indicatorSize))
        
        indicator.layer.cornerRadius = indicator.frame.size.height/2
        if let color = viewController?.navigationController?.navigationBar.barTintColor {
            activityIndicatorActiveBackgroundColor = color
        }
        self.backgroundColor = UIColor.clear
        
        self.activityIndicator = indicator
        self.refreshLabel = refreshLabel
        self.scrollView = scrollView
        self.viewController = viewController
        
        
        scrollView.addSubview(indicator)
        scrollView.addSubview(self)
        scrollView.sendSubview(toBack: self)
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
                activityIndicator?.frame.origin.x = rect.size.width - indicatorSize - indicatorOffset.x
            } else if let indicator = activityIndicator {
                indicator.frame.origin.x = (self.frame.width - indicator.frame.width)/2
            }
        }
    }
    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
        scrollView?.removeObserver(self, forKeyPath: "frame")
    }
    private func drag(offset:CGPoint) {
        var scrollViewOffset = (offset.y * -1)
        if let margins = scrollView?.layoutMargins {
            scrollViewOffset -= margins.top
        }
        if isRefreshing == false{
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
            if isRefreshing == false && capReached == false {
                tapticFeedback.selectionChanged()
            }
            capReached = true
            if scrollView?.isDragging == false && isRefreshing == false {
                startRefreshing()
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
    public func startRefreshing(force:Bool = false) {
        if isRefreshing {
            return
        }
        guard let scrollView = scrollView else {
            return
        }
        guard let indicator = activityIndicator  else {
            return
        }
        if style == .scrollView {
            if force {
                indicator.frame.origin.x = scrollView.frame.size.width
            }
            indicator.effectView?.isHidden = true
            indicator.backgroundColor = activityIndicatorActiveBackgroundColor
            indicator.color = UIColor.white
            UIView.animate(withDuration: 0.3, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIViewAnimationOptions(), animations: {
                self.refreshLabel?.alpha = 0
                indicator.frame.origin.x = scrollView.frame.size.width - self.indicatorSize - self.indicatorOffset.x
            }) { (done) in
                self.didPullDown?()
            }
            indicator.startAnimating()
        } else if style == .navigationBar {
            indicator.alpha = 0
            let headerIndicator = LineActivityIndicator(frame: CGRect(x: 0, y: force ? 0 : navigationItemHeight, width: indicatorSize, height: indicatorSize))
            headerIndicator.tintColor = self.viewController?.navigationController?.navigationBar.tintColor
            self.titleView = self.viewController?.navigationItem.titleView
            viewController?.navigationItem.titleView = headerIndicator
            UIView.animate(withDuration: 0.3, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIViewAnimationOptions(), animations: {
                self.refreshLabel?.alpha = 0
                headerIndicator.frame.origin.y = 0
            }) { (done) in
                self.didPullDown?()
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
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIViewAnimationOptions(), animations: {
                indicator.frame.origin.x = scrollView.frame.size.width
            }) { (done) in
                //indicator.effectView?.isHidden = true
                indicator.backgroundColor = UIColor.clear
                indicator.stopAnimating()
                self.isRefreshing = false
                indicator.color = self.tintColor
            }
        } else if style == .navigationBar, let headerIndicator = viewController?.navigationItem.titleView as? ActivityIndicator {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIViewAnimationOptions(), animations: {
                headerIndicator.frame.origin.y = self.navigationItemHeight * -1
            }) { (done) in
                self.viewController?.navigationItem.titleView = self.titleView
                self.titleView = nil
                self.isRefreshing = false
            }
        }
        self.tapticFeedback.selectionChanged()
    }
}
