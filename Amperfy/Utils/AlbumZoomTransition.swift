//
//  AlbumZoomTransition.swift
//  Amperfy
//
//  Created on 26.03.24.
//  Copyright (c) 2024. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import AmperfyKit

// MARK: - AlbumTransitionable
/// Protocol that defines requirements for view controllers participating in album zoom transitions
protocol AlbumTransitionable {
    /// Returns the image view that will be animating during transition
    func transitionImageView() -> UIImageView?
    
    /// The album entity being displayed
    var album: Album! { get }
}

// MARK: - AlbumZoomTransitionDelegate
/// Manages zoom transitions between album views
class AlbumZoomTransitionDelegate: NSObject, UINavigationControllerDelegate {
    // Keep track of the source frame to restore when navigating back
    private var sourceFrame: CGRect = .zero
    private var sourceView: UIView?
    private var sourceCornerRadius: CGFloat = 0
    
    // Animation durations and timing
    private let animationDuration: TimeInterval = 0.4
    
    // MARK: - UINavigationControllerDelegate
    
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        // Only handle transitions between album-related screens
        switch operation {
        case .push:
            guard let sourceVC = fromVC as? AlbumTransitionable,
                  let destinationVC = toVC as? AlbumTransitionable,
                  sourceVC.album.id == destinationVC.album.id,
                  let sourceImageView = sourceVC.transitionImageView()
            else {
                return nil
            }
            
            // Save the source frame for later use when navigating back
            if let window = fromVC.view.window {
                sourceFrame = sourceImageView.convert(sourceImageView.bounds, to: window)
                sourceView = sourceImageView
                sourceCornerRadius = sourceImageView.layer.cornerRadius
            }
            
            return AlbumZoomInTransition(
                sourceFrame: sourceFrame,
                sourceCornerRadius: sourceCornerRadius,
                duration: animationDuration
            )
            
        case .pop:
            guard let sourceVC = fromVC as? AlbumTransitionable,
                  let destinationVC = toVC as? AlbumTransitionable,
                  sourceVC.album.id == destinationVC.album.id,
                  let _ = sourceVC.transitionImageView(),
                  let _ = destinationVC.transitionImageView()
            else {
                return nil
            }
            
            // Only create a zoom out transition if we have a valid source frame from a previous push
            guard sourceFrame != .zero else {
                return nil
            }
            
            return AlbumZoomOutTransition(
                destinationFrame: sourceFrame,
                destinationCornerRadius: sourceCornerRadius,
                duration: animationDuration
            )
            
        default:
            return nil
        }
    }
}

// MARK: - AlbumZoomInTransition

class AlbumZoomInTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let sourceFrame: CGRect
    private let sourceCornerRadius: CGFloat
    private let duration: TimeInterval
    
    init(sourceFrame: CGRect, sourceCornerRadius: CGFloat, duration: TimeInterval) {
        self.sourceFrame = sourceFrame
        self.sourceCornerRadius = sourceCornerRadius
        self.duration = duration
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? AlbumTransitionable,
              let fromVC = transitionContext.viewController(forKey: .from),
              let toView = transitionContext.view(forKey: .to),
              let destinationImageView = toVC.transitionImageView()
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        
        // Add destination view to container but make it initially transparent
        toView.frame = transitionContext.finalFrame(for: toVC as! UIViewController)
        containerView.addSubview(toView)
        toView.alpha = 0
        
        // Create a snapshot of the source image view
        let transitionImageView = UIImageView(frame: sourceFrame)
        transitionImageView.image = destinationImageView.image
        transitionImageView.contentMode = .scaleAspectFill
        transitionImageView.clipsToBounds = true
        transitionImageView.layer.cornerRadius = sourceCornerRadius
        containerView.addSubview(transitionImageView)
        
        // Calculate destination frame
        let finalFrame = destinationImageView.convert(destinationImageView.bounds, to: containerView)
        
        // Make destination image view initially transparent
        destinationImageView.alpha = 0
        
        // Calculate spring animation parameters
        let damping: CGFloat = 0.8
        let velocity: CGFloat = 0.6
        
        // Animate transition with spring effect for natural feel
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: .curveEaseInOut,
            animations: {
                // Animate position, size and corner radius
                transitionImageView.frame = finalFrame
                transitionImageView.layer.cornerRadius = destinationImageView.layer.cornerRadius
                
                // Fade in the destination view
                toView.alpha = 1
            },
            completion: { _ in
                // Clean up and finish transition
                destinationImageView.alpha = 1
                transitionImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

// MARK: - AlbumZoomOutTransition

class AlbumZoomOutTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let destinationFrame: CGRect
    private let destinationCornerRadius: CGFloat
    private let duration: TimeInterval
    
    init(destinationFrame: CGRect, destinationCornerRadius: CGFloat, duration: TimeInterval) {
        self.destinationFrame = destinationFrame
        self.destinationCornerRadius = destinationCornerRadius
        self.duration = duration
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to),
              let fromVC = transitionContext.viewController(forKey: .from) as? AlbumTransitionable,
              let toView = transitionContext.view(forKey: .to),
              let sourceImageView = fromVC.transitionImageView()
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        
        // Add destination view to container but underneath the source view
        toView.frame = transitionContext.finalFrame(for: toVC)
        containerView.addSubview(toView)
        
        // Create a snapshot of the source image view
        let transitionImageView = UIImageView(frame: sourceImageView.convert(sourceImageView.bounds, to: containerView))
        transitionImageView.image = sourceImageView.image
        transitionImageView.contentMode = .scaleAspectFill
        transitionImageView.clipsToBounds = true
        transitionImageView.layer.cornerRadius = sourceImageView.layer.cornerRadius
        containerView.addSubview(transitionImageView)
        
        // Make source image view initially transparent
        sourceImageView.alpha = 0
        
        // Calculate spring animation parameters
        let damping: CGFloat = 0.85
        let velocity: CGFloat = 0.5
        
        // Animate transition with spring effect for natural feel
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: .curveEaseInOut,
            animations: {
                // Animate position, size and corner radius
                transitionImageView.frame = self.destinationFrame
                transitionImageView.layer.cornerRadius = self.destinationCornerRadius
                
                // Fade out the source view controller
                fromVC.view.alpha = 0
            },
            completion: { _ in
                // Clean up and finish transition
                sourceImageView.alpha = 1
                transitionImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

// MARK: - Extension for UIViewController

extension UIViewController {
    /// Returns the AlbumZoomTransitionDelegate from the navigation controller, creating it if needed
    var albumZoomTransitionDelegate: AlbumZoomTransitionDelegate {
        if let delegate = navigationController?.delegate as? AlbumZoomTransitionDelegate {
            return delegate
        }
        
        let delegate = AlbumZoomTransitionDelegate()
        navigationController?.delegate = delegate
        return delegate
    }
    
    /// Sets up zoom transitions for album view controllers
    func setupAlbumZoomTransitions() {
        // This method just accesses the delegate property which sets it up if needed
        _ = albumZoomTransitionDelegate
    }
} 