//
//  View+Ripple.swift
//
//  Created by Yanis Plumit on 21.11.2022.
//


import Foundation
import SwiftUI
import ViewOnTouch

public extension View {
    func rippleEffect(color: Color, viewModel: RippleViewModel, clipShape: any Shape) -> some View {
        modifier(RippleViewModifier(color: color, viewModel: viewModel, clipShape: clipShape))
    }
    
    @available(*, deprecated, renamed: "rippleEffect")
    func addRipple<S>(color: Color, rippleViewModel: RippleViewModel, clipShape: S) -> some View where S : Shape {
        self
            .overlay(content: {
                RippleView(rippleViewModel: rippleViewModel, color: UIColor(color))
                    .clipShape(clipShape)
            })
    }
}
 
public extension View {
    func addRippleTouchHandler(viewModel: RippleViewModel,
                               tapAction: (() -> Void)? = nil,
                               longGestureAction: ((CGPoint, RippleViewGestureState) -> Void)? = nil) -> some View {
        self
            .onTouch(type: longGestureAction == nil ? .allWithoutLongGesture : .all,
                     perform: { location, event in
                switch event {
                case .started:
                    viewModel.isTouchHandling = true
                    viewModel.touchDown?(location)
                case .moved:
                    viewModel.touchMove?(location)
                case .ended:
                    viewModel.isTouchHandling = false
                    viewModel.touchUp?(location)
                case .tapGesture where !viewModel.isTouchHandling:
                    viewModel.touchDown?(location)
                    viewModel.touchUp?(location)
                    tapAction?()
                case .longGestureStarted:
                    longGestureAction?(location, .started)
                case .longGestureMoved:
                    longGestureAction?(location, .moved)
                case .longGestureEnded:
                    longGestureAction?(location, .ended)
                default:
                    break
                }
            })
    }
}

struct RippleView: UIViewRepresentable {
    let rippleViewModel: RippleViewModel
    let color: UIColor
    
    func makeUIView(context: Context) -> RippleViewUIView {
        let view = RippleViewUIView()
        view.rippleColor = self.color
        view.rippleViewModel = rippleViewModel
        return view
    }
    
    func updateUIView(_ uiView: RippleViewUIView, context: Context) {
    }
}

extension RippleView {
    class RippleViewUIView: UIView {
        
        var rippleColor: UIColor = .clear {
            didSet {
                maskLayer.fillColor = rippleColor.cgColor
            }
        }
        
        var rippleViewModel: RippleViewModel? {
            didSet {
                rippleViewModel?.touchDown = {[weak self] touchPoint in
                    guard let self = self else { return }
                    self.updateCenter(touchPoint: touchPoint)
                    self.touchDown()
                }
                rippleViewModel?.touchMove = {[weak self] touchPoint in
                    guard let self = self else { return }
                    self.updateCenter(touchPoint: touchPoint)
                }
                rippleViewModel?.touchUp = {[weak self] touchPoint in
                    guard let self = self else { return }
                    self.containerView.center = touchPoint
                    self.touchUp()
                }
            }
        }
        
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
            let scale: CGFloat = rippleR(touchPoint: touchPoint) / maxRippleR * 0.7
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
}

fileprivate extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
