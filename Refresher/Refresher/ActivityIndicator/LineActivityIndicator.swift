//
//  LineActivityIndicator.swift
//  Refresher
//
//  Created by Tomas Green on 2017-09-21.
//  Copyright © 2017 Tomas Green. All rights reserved.
//

import UIKit

fileprivate func angleFor(index:Int) -> CGFloat {
    return (CGFloat.pi / 180 ) * 30 * CGFloat(index)
}

@IBDesignable public class LineActivityIndicator: ActivityIndicator,CAAnimationDelegate {
    @IBInspectable public var rotationDuration:Double = 1
    private var fragments:Double = 12
    
    override public var color:UIColor {
        get {
            return self.tintColor
        }
        set {
            self.tintColor = newValue
            for i in 0...Int(fragments) {
                guard let fragment = self.viewWithTag(i + 1) as? UIImageView else {
                    continue
                }
                fragment.tintColor = newValue
            }
        }
    }
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.removeFragmentAnimations()
        self.isLoading = false
        self.alpha = 0
    }
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        for i in 0...Int(self.fragments) {
            guard let frament = self.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            frament.transform = .identity
            frament.alpha = 1
            frament.transform = CGAffineTransform.init(rotationAngle: angleFor(index: i))
        }
    } 
    public override func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: LineActivityIndicator.self)
        let nib = UINib(nibName: String(describing: LineActivityIndicator.self), bundle: bundle)
        
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return UIView()
        }
        return view
    }
    override public func setup() {
        super.setup()
        for i in 0...Int(fragments) {
            guard let fragment = self.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            fragment.alpha = 0
        }
    }
    public override func fadeFragments(offset:CGFloat, capHeight:CGFloat = 25, maxHeight:CGFloat = 125) {
        if isLoading == true {
            return
        }
        self.alpha = 1
        let sizePerFragment = (maxHeight - capHeight)/CGFloat(fragments)
        let rotationPerFragment = (CGFloat.pi / 180 ) * (360/CGFloat(fragments))
        for i in 0...Int(fragments) {
            guard let fragment = self.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            if sizePerFragment * CGFloat(i + 1) < offset - capHeight {
                fragment.alpha = 1
            } else {
                fragment.alpha = 0
            }
            
            let from = rotationPerFragment * CGFloat(i)
            fragment.transform = CGAffineTransform.init(rotationAngle: from)
        }
    }
    func removeFragmentAnimations() {
        
        for i in 0...Int(self.fragments) {
            guard let fragment = self.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            fragment.transform = .identity
            fragment.layer.removeAllAnimations()
        }
    }
    public override func stopAnimating() {
        if !isLoading {
            return
        }
        self.removeFragmentAnimations()
        self.isLoading = false
        self.alpha = 0
    }
    public override func startAnimating() {
        if isLoading {
            return
        }
        self.alpha = 1
        self.animateFragments()
        isLoading = true
    }
    public override func animateFragments() {
        if isLoading {
            return
        }
        self.alpha = 1
        let timePerFramegment = rotationDuration/fragments
        let now = CACurrentMediaTime()
        for i in 0...Int(fragments) {
            guard let fragment = self.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            fragment.tintColor = self.tintColor
            fragment.alpha = 1
            fragment.transform = .identity
            let from = angleFor(index: i)
            let to = (CGFloat.pi / 180 ) * 360
            
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.fromValue = 1
            fadeAnimation.toValue = 0
            fadeAnimation.duration = rotationDuration
            fadeAnimation.beginTime = now + timePerFramegment*Double(i)
            fadeAnimation.repeatCount = Float.infinity
            fragment.layer.add(fadeAnimation, forKey: fadeAnimation.keyPath)
            
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            fragment.transform = CGAffineTransform.init(rotationAngle: from)
            rotationAnimation.fromValue = from
            rotationAnimation.toValue = from + to
            rotationAnimation.duration = rotationDuration * 1.8
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            rotationAnimation.repeatCount = Float.infinity
            fragment.layer.add(rotationAnimation, forKey: rotationAnimation.keyPath)
            
        }
        
        self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: UIViewAnimationOptions(), animations: {
            self.transform = .identity
        })
        self.isLoading = true
    }
}
