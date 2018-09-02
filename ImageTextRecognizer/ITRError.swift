//
//  ITRError.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 4/4/17.
//  Copyright © 2017 Tom and Jerry. All rights reserved.
//

import Foundation

// Struct for all error handling, will implement in later version of app

struct ITRError {
    let errorCode: Int
    let errorDescription: String
    
    init(code: Int, description: String) {
        errorCode = code
        errorDescription = description
    }
}
