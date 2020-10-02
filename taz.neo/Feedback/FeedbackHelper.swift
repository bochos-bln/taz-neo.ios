//
//  FeedbackHelper.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 02.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import NorthLib

extension UIView{
  static func seperator(color:UIColor? = nil, thickness:CGFloat = 0.3) -> UIView{
    let v = UIView()
    
    if let c = color {
      v.backgroundColor = c
    } else {
      v.backgroundColor = .lightGray
    }
    
    v.pinSize(CGSize(width: thickness, height: thickness), priority: .fittingSizeLevel)
    return v
  }
}

extension UIImageView {
  func addAspectRatioConstraint(image: UIImage?) {
    if let image = image {
      removeAspectRatioConstraint()
      let aspectRatio = image.size.width / image.size.height
      let constraint = NSLayoutConstraint(item: self, attribute: .width,
                                          relatedBy: .equal,
                                          toItem: self, attribute: .height,
                                          multiplier: aspectRatio, constant: 0.0)
      addConstraint(constraint)
    }
  }
  
  func removeAspectRatioConstraint() {
    for constraint in self.constraints {
      if (constraint.firstItem as? UIImageView) == self,
        (constraint.secondItem as? UIImageView) == self {
        removeConstraint(constraint)
      }
    }
  }
}

public class XImageView: UIImageView {
  override public var image: UIImage?{
    didSet{
      addAspectRatioConstraint(image: image)
    }
  }
}
