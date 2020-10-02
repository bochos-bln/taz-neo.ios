//
//  TazTextView.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 02.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit
import NorthLib

// MARK: - TazTextView
class TazTextView : Padded.TextView {
  static let recomendedHeight:CGFloat = 56.0
  private let border = BorderView()
  let topLabel = UILabel()
  let bottomLabel = UILabel()
  private var borderHeightConstraint: NSLayoutConstraint?
  
  
  // MARK: > pwInput
  required convenience init(prefilledText: String? = nil,
                color: UIColor = Const.SetColor.CIColor.color,
                textColor: UIColor = Const.SetColor.CTDate.color,
                height: CGFloat = TazTextField.recomendedHeight,
                paddingTop: CGFloat = Const.Size.TextViewPadding,
                paddingBottom: CGFloat = Const.Size.TextViewPadding,
                enablesReturnKeyAutomatically: Bool = false,
                keyboardType: UIKeyboardType = .default,
                autocapitalizationType: UITextAutocapitalizationType = .words,
                target: Any? = nil,
                action: Selector? = nil) {
    self.init()
    pinHeight(height)
    self.paddingTop = paddingTop
    self.paddingBottom = paddingBottom
    
    self.textColor = textColor
    self.keyboardType = keyboardType
    self.textContentType = textContentType
    self.autocapitalizationType = autocapitalizationType
    self.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
    self.isSecureTextEntry = isSecureTextEntry
    setup()
  }
  
  
  // MARK: > init
//  public override init(frame: CGRect){
//    super.init(frame: frame)
//    setup()
//  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  func setup(){
    self.addSubview(border)
    self.delegate = self
    self.border.backgroundColor = Const.SetColor.ForegroundHeavy.color
    self.borderHeightConstraint = border.pinHeight(1)
    pin(border.left, to: self.left)
    pin(border.right, to: self.right)
    pin(border.bottom, to: self.bottom, dist: -15)
//    self.addTarget(self, action: #selector(textFieldEditingDidChange),
//                   for: UIControl.Event.editingChanged)
//    self.addTarget(self, action: #selector(textFieldEditingDidBegin),
//                   for: UIControl.Event.editingDidBegin)
//    self.addTarget(self, action: #selector(textFieldEditingDidEnd),
//                   for: UIControl.Event.editingDidEnd)
  }
  
  override open var text: String?{
    didSet{
      if let _text = text, _text.isEmpty {
        UIView.animate(seconds: 0.3) { [weak self] in
          self?.topLabel.alpha = 0.0
        }
      }
      else {
        UIView.animate(seconds: 0.3) { [weak self] in
          self?.topLabel.alpha = 1.0
        }
      }
    }
  }
  
 
  
  // MARK: > bottomMessage
  open var bottomMessage: String?{
    didSet{
      bottomLabel.text = bottomMessage
      if bottomLabel.superview == nil && bottomMessage?.isEmpty == false{
        bottomLabel.alpha = 0.0
        bottomLabel.numberOfLines = 1
        self.addSubview(bottomLabel)
        pin(bottomLabel.left, to: self.left)
        pin(bottomLabel.right, to: self.right)
        pin(bottomLabel.bottom, to: self.bottom)
        bottomLabel.font = Const.Fonts.contentFont(size: Const.Size.MiniPageNumberFontSize)
        bottomLabel.textColor = Const.SetColor.CIColor.color
      }
      
      UIView.animate(seconds: 0.3) { [weak self] in
        self?.bottomLabel.alpha = self?.bottomMessage?.isEmpty == false ? 1.0 : 0.0
      }
    }
  }
  
  // MARK: > inputToolbar
  lazy var inputToolbar: UIToolbar = createToolbar()
}

// MARK: - TazTextField : Toolbar
extension TazTextView{
  
  fileprivate func createToolbar() -> UIToolbar{
    /// setting toolbar width fixes the h Autolayout issue, unfortunatly not the v one no matter which height
    let toolbar =  UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0))
    toolbar.barStyle = .default
    toolbar.isTranslucent = true
    toolbar.sizeToFit()
    
    /// Info: Issue with Autolayout
    /// the solution did not solve our problem:
    /// https://developer.apple.com/forums/thread/121474
    /// because we use autocorection/password toolbar also
    /// also the following options did not worked:
    ///   UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
    ///   toolbar.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
    ///   toolbar.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
    ///   toolbar.autoresizesSubviews = false
    ///   toolbar.translatesAutoresizingMaskIntoConstraints = true/false
    ///   ....
    ///   toolbar.sizeToFit()
    ///   toolbar.pinHeight(toolbar.frame.size.height).priority = .required
    ///   ....
    /// Maybe extend: CustomToolbar : UIToolbar and invoke updateConstraints/layoutSubviews
    /// to reduce constraint priority or set frame/size
    
    let doneButton  = UIBarButtonItem(image: UIImage(name: "checkmark")?.withRenderingMode(.alwaysTemplate),
                                      style: .done,
                                      target: self,
                                      action: #selector(textFieldToolbarDoneButtonPressed))
    
    let prevButton  = UIBarButtonItem(title: "❮",
                                      style: .plain,
                                      target: self,
                                      action: #selector(textFieldToolbarPrevButtonPressed))
    
    
    let nextButton  = UIBarButtonItem(title: "❯",
                                      style: .plain,
                                      target: self,
                                      action: #selector(textFieldToolbarNextButtonPressed))
    
    prevButton.tintColor = Const.Colors.ciColor
    nextButton.tintColor = Const.Colors.ciColor
    doneButton.tintColor = Const.Colors.ciColor
    
    let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let fixedSpaceButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    fixedSpaceButton.width = 30
    
    toolbar.setItems([prevButton, fixedSpaceButton, nextButton, flexibleSpaceButton, doneButton], animated: false)
    toolbar.isUserInteractionEnabled = true
    
    return toolbar
  }
  
  @objc func textFieldToolbarDoneButtonPressed(sender: UIBarButtonItem) {
    self.resignFirstResponder()
  }
  
  @objc func textFieldToolbarPrevButtonPressed(sender: UIBarButtonItem) {
    if let nextField = self.superview?.viewWithTag(self.tag - 1) as? UITextField {
      nextField.becomeFirstResponder()
    } else {
      self.resignFirstResponder()
    }
  }
  
  @objc func textFieldToolbarNextButtonPressed(sender: UIBarButtonItem) {
    nextOrEndEdit()
  }
  
  func nextOrEndEdit(){
    if let nextField = self.superview?.viewWithTag(self.tag + 1) as? UITextField {
      nextField.becomeFirstResponder()
    } else {
      self.resignFirstResponder()
    }
  }
}

// MARK: - TazTextField : UITextFieldDelegate
extension TazTextView :  UITextViewDelegate{
  @objc public func textFieldEditingDidChange(_ textField: UITextField) {
    if let _text = textField.text, _text.isEmpty {
      UIView.animate(seconds: 0.3) { [weak self] in
        self?.topLabel.alpha = 0.0
      }
    }
    else {
      UIView.animate(seconds: 0.3) { [weak self] in
        self?.topLabel.alpha = 1.0
      }
    }
  }
  
  @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    nextOrEndEdit()
    return true
  }
  
  @objc public func textFieldEditingDidBegin(_ textField: UITextField) {
    textField.inputAccessoryView = inputToolbar
    
    UIView.animate(seconds: 0.3) { [weak self] in
      self?.border.backgroundColor = Const.SetColor.CIColor.color
      self?.topLabel.textColor = Const.SetColor.CIColor.color
      self?.borderHeightConstraint?.constant = 2.0
    }
  }
  
  @objc public func textFieldEditingDidEnd(_ textField: UITextField) {
    //textField.text = textField.text?.trim //work not good "123 456" => "123"
    //push (e.g.) pw forgott child let end too late
    UIView.animate(seconds: 0.3) { [weak self] in
      self?.border.backgroundColor = Const.SetColor.ForegroundHeavy.color
      self?.topLabel.textColor = Const.SetColor.ForegroundHeavy.color
      self?.borderHeightConstraint?.constant = 1.0
    }
  }
}
