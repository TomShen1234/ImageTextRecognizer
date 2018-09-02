//
//  Delay.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 3/9/17.
//  Copyright © 2017 Tom and Jerry. All rights reserved.
//

import Foundation

func delay(_ second: Double, block: @escaping ()->()) {
    let deadlineTime = DispatchTime.now() + second
    DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: block)
}
