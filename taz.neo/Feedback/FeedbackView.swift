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

/**
 
 UI:
 
 subjectLabel   :::: sendButton
 additionalInfoLabel (wenn angemeldet!!)
 senderMailTextField
 seperator
 messageTextView
 seperator
 lastInteractionTextView  (ONLY ERROR)
 seperator  (ONLY ERROR)
 environmentTextView (ONLY ERROR)
 seperator  (ONLY ERROR)
 attachments
 
 */

public class FeedbackView : UIView {
  var type:FeedbackType
  public let subjectLabel = UILabel()
  public let messageTextView = ViewWithTextView()
  public let lastInteractionTextView = ViewWithTextView()
  public let environmentTextView = ViewWithTextView()
  public let senderMail = UITextField()
  public let sendButton = UIButton()
  public let additionalInfoLabel = UILabel()
  
  public let screenshotAttachmentButton = XImageView()
  public let logAttachmentButton = XImageView()
  
  init(type: FeedbackType, subject:String, bodyText:String) {
    self.type = type
    self.subjectLabel.text = subject
    self.messageTextView.text = bodyText
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    print("deinit: FeedbackView ;-)")
  }
  
  private func setup() {
    self.onTapping { [weak self] (_) in
      self?.endEditing(false)
    }
    
    messageTextView.topMessage = "Ihre Nachhricht"
    lastInteractionTextView.topMessage = "Letzte Interaktion"
    environmentTextView.topMessage = "Zustand"
      
    messageTextView.placeholder = "Beschreiben Sie ihr Problem bitte hier."
    lastInteractionTextView.placeholder = "Was waren die letzten Aktionen, die Sie mit der App durchgeführt haben, bevor das Problem aufgetreten ist?"
    
    environmentTextView.placeholder = "Beschreiben Sie mögliche Außeneinflüsse bitte hier. War das WLAN an?, Benutzen Sie eine Firewall, Proxy? Gab es Netzwerkprobleme, genügend Speicher, aussreichend Akku..."
    senderMail.placeholder = "mail@mail.cc"
    
    //Subject & Send Button
    let hStack1 = UIStackView()
    hStack1.alignment = .fill
    hStack1.axis = .horizontal
    ///Content: subjectLabel

    subjectLabel.numberOfLines = 0
    subjectLabel.font = UIFont.boldSystemFont(ofSize: Const.Size.DefaultFontSize)
    /// Content: sendButton Style
    sendButton.isEnabled = true
    sendButton.setBackgroundColor(color: .blue, forState: .normal)
    sendButton.setBackgroundColor(color: .lightGray, forState: .disabled)
    sendButton.layer.cornerRadius = 21
    sendButton.setImage(UIImage(name: "arrow.up"), for: .normal)
    sendButton.imageView?.tintColor = .white
    ///Add
    hStack1.addArrangedSubview(subjectLabel)
    hStack1.addArrangedSubview(sendButton)
    
    //Attatchment Container
    let hStack2 = UIView()
    hStack2.addSubview(screenshotAttachmentButton)
    logAttachmentButton.contentMode = .scaleAspectFit
    screenshotAttachmentButton.contentMode = .scaleAspectFit
    hStack2.addSubview(logAttachmentButton)
    logAttachmentButton.image = UIImage(name: "doc.text")
    
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 4.0//Seperators increase spacing!
    stack.addArrangedSubview(hStack1)
    stack.addArrangedSubview(additionalInfoLabel)
    stack.addArrangedSubview(senderMail)
    senderMail.tag = 0
    stack.addArrangedSubview(UIView.seperator())
    stack.addArrangedSubview(messageTextView)
    messageTextView.tag = 1
    if type == .error {
      stack.addArrangedSubview(UIView.seperator())
      stack.addArrangedSubview(lastInteractionTextView)
      lastInteractionTextView.tag = 2
      stack.addArrangedSubview(UIView.seperator())
      stack.addArrangedSubview(environmentTextView)
      environmentTextView.tag = 3
    }
    stack.addArrangedSubview(UIView.seperator())
    stack.addArrangedSubview(hStack2)
    
    let scrollView = UIScrollView()
    
    scrollView.addSubview(stack)
    pin(stack, to: scrollView, dist: 12)
    stack.pinWidth(UIScreen.main.bounds.size.width - 24, priority: .required)
    
    self.addSubview(scrollView)
    pin(scrollView, toSafe: self)
    
    ///Set Constraints after added to Stack View otherwise Contraint Errosrs are displayed
    sendButton.pinSize(CGSize(width: 42, height: 42))
    screenshotAttachmentButton.pinHeight(70)
    logAttachmentButton.pinHeight(70)
    pin(screenshotAttachmentButton, to: hStack2, exclude: .right)
    pin(logAttachmentButton, to: hStack2, exclude: .left)
  }
}

