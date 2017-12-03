//
//  ActivityIndicator.swift
//  Refresher
//
//  Created by Tomas Green on 2017-10-16.
//  Copyright © 2017 omas Green. All rights reserved.
//

import UIKit

public class ActivityIndicator: UIView {
    @IBOutlet var effectView:UIVisualEffectView?
    internal var isLoading:Bool = false
    public var isAnimating:Bool {
        set {
            if newValue {
                startAnimating()
            } else {
                stopAnimating()
            }
            isLoading = newValue
        }
        get {
            return isLoading
        }
    }
    open var color:UIColor {
        get {
            return self.tintColor
        }
        set {
            self.tintColor = newValue
        }
    }
    internal var contentView = UIView()
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        setup()
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    open func loadViewFromNib() -> UIView {
        return UIView()
    }
    open func setup() {
        contentView = loadViewFromNib()
        contentView.frame = bounds
        self.effectView?.isHidden = true
        self.effectView?.layer.cornerRadius = self.frame.size.height/2
        self.effectView?.layer.masksToBounds = true
        self.addSubview(contentView)
        self.alpha = 0
    }
    open func startAnimating() {
        if isLoading {
            return
        }
        self.alpha = 0
        animateFragments()
        UIView.animate(withDuration: 0.5) {
            self.alpha = 1
        }
        isLoading = true
    }
    open func stopAnimating() {
        if !isLoading {
            return
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { (success) in
            self.removeAnimations()
        }
        self.isLoading = false
    }
    open func removeAnimations() {

    }
    open func animateFragments() {

    }
    open func fadeFragments(offset:CGFloat, capHeight:CGFloat = 25, maxHeight:CGFloat = 125) {
        
    }
}
