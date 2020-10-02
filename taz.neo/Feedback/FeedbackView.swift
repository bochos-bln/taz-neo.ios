//
//  FeedbackView.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 02.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import NorthLib
import UIKit

public class FeedbackView : UIView {
  static var defaultFontSize = CGFloat(16)
  static var subjectFontSize = CGFloat(32)
  
  let stack = UIStackView()
  
  public let subjectLabel = UILabel()
  public let subjectSubLabel = UILabel()
  public let additionalInfoLabel = UILabel()
  public let senderMail = UITextField()
  public let sendButton = UIButton()
  public let messageTextView = UITextView()
  public let seperator1 = UIView.seperator()
  public let seperator2 = UIView.seperator()
  public let screenshotAttachmentButton = XImageView()// ScaledHeightImageView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 60)))
  public let logAttachmentButton = XImageView()//ScaledHeightImageView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 60)))
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  @objc func resignActive() {
    messageTextView.resignFirstResponder()
  }
  
  private func setup() {
    self.onTapping { [weak self] (_) in
      guard let self = self else { return }
      if self.messageTextView.isFirstResponder {
        self.messageTextView.resignFirstResponder()
      }
    }
    
    additionalInfoLabel.text = "additionalInfoLabel.text"
    senderMail.placeholder = "Antwort Mail"
    
    let hStack1 = UIStackView()
    let hStack2 = UIView()
    
    hStack1.alignment = .fill
    hStack1.axis = .horizontal
    stack.axis = .vertical
    stack.spacing = 4.0//Seperators increase spacing!
    /// Style
    sendButton.isEnabled = true
    sendButton.setBackgroundColor(color: .blue, forState: .normal)
    sendButton.setBackgroundColor(color: .lightGray, forState: .disabled)
    sendButton.layer.cornerRadius = 21
    sendButton.setImage(UIImage(name: "arrow.up"), for: .normal)
    sendButton.imageView?.tintColor = .white
    subjectLabel.numberOfLines = 0
    subjectLabel.font = UIFont.boldSystemFont(ofSize: Self.subjectFontSize)
    logAttachmentButton.image = UIImage(name: "doc.text")
    
    screenshotAttachmentButton.contentMode = .scaleAspectFit
    logAttachmentButton.contentMode = .scaleAspectFit
    
    /// Add
    hStack1.addArrangedSubview(subjectLabel)
    hStack1.addArrangedSubview(sendButton)
    
    hStack2.addSubview(screenshotAttachmentButton)
    logAttachmentButton.contentMode = .scaleAspectFit
    screenshotAttachmentButton.contentMode = .scaleAspectFit
    hStack2.addSubview(logAttachmentButton)
    
    //Set Constraints after added to Stack View otherwise Contraint Errosrs are displayed
    sendButton.pinSize(CGSize(width: 42, height: 42))
    
    screenshotAttachmentButton.pinHeight(70)
    logAttachmentButton.pinHeight(70)
    
    pin(screenshotAttachmentButton, to: hStack2, exclude: .right)
    pin(logAttachmentButton, to: hStack2, exclude: .left)
    
    stack.addArrangedSubview(hStack1)
    stack.addArrangedSubview(additionalInfoLabel)
    stack.addArrangedSubview(senderMail)
    stack.addArrangedSubview(seperator1)
    stack.addArrangedSubview(messageTextView)
    stack.addArrangedSubview(seperator2)
    stack.addArrangedSubview(hStack2)
    
    self.addSubview(stack)
    pin(stack, toSafe: self, dist: 12)
  }
}
