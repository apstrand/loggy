//
//  LabelTapHandler.swift
//  LoggyTools
//
//  Created by Peter Strand on 2017-06-29.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import UIKit

public class LabelTapHandler {
  let callback : (UILabel) -> Void
  let tapGesture = UITapGestureRecognizer()
  let view : UILabel
  
  public init(_ view : UILabel, _ cb: @escaping (UIView) -> Void) {
    self.view = view
    self.callback = cb
    self.tapGesture.numberOfTapsRequired = 1
    self.tapGesture.addTarget(self, action: #selector(LabelTapHandler.tapDetected(target:)))
    view.addGestureRecognizer(tapGesture)
  }
  
  deinit {
    self.tapGesture.removeTarget(self, action: #selector(LabelTapHandler.tapDetected(target:)))
    view.removeGestureRecognizer(tapGesture)
  }
  
  @objc func tapDetected(target: Any) {
    callback(view)
  }
}
