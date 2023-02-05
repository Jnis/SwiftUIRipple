//
//  DefaultRippleUIView.swift
//  
//
//  Created by Yanis Plumit on 05.02.2023.
//

import UIKit

extension DefaultRippleUIView: RippleUIViewProtocol {
    struct ViewModel {
        let rippleColor: UIColor
        let fillPercent: CGFloat
    }
    
    convenience init(configuration: ViewModel) {
        self.init()
        fillPercent = configuration.fillPercent
        maskLayer.fillColor = configuration.rippleColor.cgColor
    }
    
    func touchDown(touchPoint: CGPoint) {
        self.updateCenter(touchPoint: touchPoint)
        self.touchDown()
    }
    func touchMove(touchPoint: CGPoint) {
        self.updateCenter(touchPoint: touchPoint)
    }
    func touchUp(touchPoint: CGPoint) {
        self.containerView.center = touchPoint
        self.touchUp()
    }
}

final class DefaultRippleUIView: UIView {
    var fillPercent: CGFloat = 1
    
    private var maxRippleR: CGFloat {
        return max(self.bounds.size.width, self.bounds.size.height)
    }
    
    private func rippleR(touchPoint: CGPoint) -> CGFloat {
        return max(
            touchPoint.distance(to: CGPoint(x: 0, y: 0)),
            touchPoint.distance(to: CGPoint(x: self.bounds.size.width, y: 0)),
            touchPoint.distance(to: CGPoint(x: 0, y: self.bounds.size.height)),
            touchPoint.distance(to: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height))
        )
    }
    
    private func updateCenter(touchPoint: CGPoint) {
        self.containerView.center = touchPoint
        let scale: CGFloat = rippleR(touchPoint: touchPoint) / maxRippleR * fillPercent
        self.containerView.transform = .init(scaleX: scale, y: scale)
    }
    
    private let maskLayer: CAShapeLayer = CAShapeLayer()
    
    private let containerView: UIView = {
        let v = UIView()
        v.frame = .zero
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    
    // Just in case you're using storyboards!
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    private func customInit() {
        isUserInteractionEnabled = false
        self.addSubview(containerView)

        containerView.layer.addSublayer(maskLayer)
        self.isHidden = true
    }
    
    private var isTouchDown = false
    private var isAnimating = false
    
    func touchUp() {
        self.isTouchDown = false
        self.hideIfNeed()
    }
    
    func touchCancel() {
        maskLayer.removeAllAnimations()
        layer.removeAllAnimations()
        self.isTouchDown = false
        self.isHidden = true
    }
    
    func touchDown() {
        maskLayer.removeAllAnimations()
        self.layer.removeAllAnimations()
        self.containerView.layer.removeAllAnimations()
        
        self.isAnimating = true
        self.isTouchDown = true
        self.alpha = 1
        self.isHidden = false
        
        let startRect = CGRect.zero
        let r: CGFloat = maxRippleR
        let endRect = startRect.insetBy(dx: -r, dy: -r)
        
        let startPath = UIBezierPath(roundedRect: startRect, cornerRadius: 0)
        let endPath = UIBezierPath(roundedRect: endRect, cornerRadius: r)
        
        CATransaction.begin()
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = startPath.cgPath
        animation.toValue = endPath.cgPath
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.0, 1, 0.5, 1)
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        
        CATransaction.setCompletionBlock {
            self.isAnimating = false
//                self.hideIfNeed()
        }
        
        maskLayer.add(animation, forKey: "rippleFill")
        CATransaction.commit()
    }
    
    private func hideIfNeed() {
        if !self.isTouchDown { // !self.isAnimating &&
            UIView.animate(withDuration: 0.3, animations: {
                self.containerView.transform = .identity
                self.alpha = 0
            }, completion: { _ in
                if !self.isTouchDown {
                    self.isHidden = true
                }
            })
        }
    }
}
