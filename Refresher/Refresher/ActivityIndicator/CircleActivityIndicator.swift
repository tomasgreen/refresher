//
//  ActivityIndcator2.swift
//  Refresher
//
//  Created by Tomas Green on 2017-10-15.
//  Copyright © 2017 Tomas Green. All rights reserved.
//

import UIKit

fileprivate func angleFor(index:Int,fragments:Int=5) -> CGFloat {
    return (CGFloat.pi / 180 ) * (360/CGFloat(fragments)) * CGFloat(index + 1)
}

@IBDesignable public class CircleActivityIndicator: ActivityIndicator {
    
    private var fragments:Double = 10
    
    public override func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: CircleActivityIndicator.self)
        let nib = UINib(nibName: String(describing: CircleActivityIndicator.self), bundle: bundle)
        
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return UIView()
        }
        return view
    }
    override public func removeAnimations() {
        for i in 0...Int(fragments) {
            guard let fragment = self.contentView.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            fragment.layer.removeAllAnimations()
            fragment.transform = .identity
        }
    }
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        resetRotation()
    }
    func resetRotation() {
        for i in 0...Int(fragments) {
            let from = angleFor(index: i)
            guard let fragment = self.contentView.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            fragment.transform = CGAffineTransform.init(rotationAngle: from)
        }
    }
    override public func fadeFragments(offset:CGFloat, capHeight:CGFloat = 0, maxHeight:CGFloat = 125) {
        if isLoading == true {
            return
        }
        self.alpha = 1
        let sizePerFragment = (maxHeight - capHeight)/CGFloat(fragments)
        let rotationPerFragment = (CGFloat.pi / 180 ) * offset
        for i in 0...Int(fragments) {
            guard let fragment = self.contentView.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            if offset > sizePerFragment * CGFloat(i) {
                fragment.alpha = (offset - sizePerFragment * CGFloat(i)) / sizePerFragment
            } else {
                fragment.alpha = 0
            }
            
            let from = angleFor(index: i)  +  rotationPerFragment
            if i%2 == 0 {
                fragment.transform = CGAffineTransform.init(rotationAngle: from)
            } else {
                fragment.transform = CGAffineTransform.init(rotationAngle: from * -1)
            }
            
        }
    }
    
    override public func animateFragments() {
        if isLoading == true {
            return
        }
        isLoading = true
        self.alpha = 1
        for i in 0...Int(fragments) {
            guard let fragment = self.contentView.viewWithTag(i + 1) as? UIImageView else {
                continue
            }
            if fragment.transform == .identity {
                let from = angleFor(index: i)
                if i%2 == 0 {
                    fragment.transform = CGAffineTransform.init(rotationAngle: from)
                } else {
                    fragment.transform = CGAffineTransform.init(rotationAngle: from * -1)
                }
            }
            let radians:Float = atan2f(Float(fragment.transform.b), Float(fragment.transform.a))
            let to =  (CGFloat.pi / 180) * 360
            fragment.alpha = 1
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.isRemovedOnCompletion = false
            rotationAnimation.duration = CircleActivityIndicator.random(min: 1, max: 2)
            rotationAnimation.fromValue = CGFloat(radians)
            if i%2 == 0 {
                rotationAnimation.toValue = CGFloat(radians) + to
            } else {
                rotationAnimation.toValue = CGFloat(radians) + to * -1
            }
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            rotationAnimation.repeatCount = Float.infinity
            fragment.layer.add(rotationAnimation, forKey: rotationAnimation.keyPath)
        }
    }
    public static var random: Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }
    public static func random(min: Double, max: Double) -> Double {
        return CircleActivityIndicator.random * (max - min) + min
    }
}


