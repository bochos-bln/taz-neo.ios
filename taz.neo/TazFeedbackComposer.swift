//
//  TazFeedbackComposer.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 30.09.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import NorthLib
/**
 TODOS
 - Total BG (Anfasser auf Transparent)
 - Text Area BG = BG
 - LOng Touch to remove
 - integrate screenshot
 - integrate log
 - tap to show
 - send feedback
 */

open class TazFeedbackComposer : FeedbackComposer{
  public static let tazShared = TazFeedbackComposer()
  
  override public init() {
    super.init()
  }
  
  let _myfeedbackViewController = TazFeedbackViewController()
  public override var feedbackViewController : FeedbackViewController {
    get {
      return _myfeedbackViewController
      
    }
  }
}
open class TazFeedbackViewController : FeedbackViewController{
  open override func viewDidLoad() {
    super.viewDidLoad()
    feedbackView.backgroundColor
      = Const.SetColor.CTBackground.color
    feedbackView.messageTextView.backgroundColor
      = Const.SetColor.ForegroundLight.color
    feedbackView.messageTextView.textColor = Const.SetColor.HText.color
  }
}
