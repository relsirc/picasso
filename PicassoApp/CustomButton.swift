//
//  CustomButton.swift
//  PicassoApp
//
//  Created by Crisler Chee on 9/10/15.
//  Copyright © 2015 Crisler. All rights reserved.
//

import Foundation
import UIKit

class CustomButton : UIButton
{
    required init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)!
        self.layer.cornerRadius = 15.0;
        self.layer.borderColor = UIColor.whiteColor().CGColor
        self.layer.borderWidth = 1.5
    }
  
}
