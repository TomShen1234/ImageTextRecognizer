//
//  Translator.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 4/4/17.
//  Copyright © 2017 Tom and Jerry. All rights reserved.
//

import Foundation

enum TranslationAPI {
    case microsoft
    case google
}

// Unfinished class for translation

class Translator {
    func translate(text: String, usingAPI translationAPI: TranslationAPI, completion: (String, ITRError) -> Void) {
        if translationAPI == .microsoft {
            let (result, error) = translateUsingMicrosoft(text)
            
            completion(result, error)
        } else if translationAPI == .google {
            
        }
    }
    
    func translateUsingMicrosoft(_ text: String) -> (String, ITRError) {
        return ("", ITRError(code: 0, description: "Hi"))
    }
    
    private func translateGoogle() -> (String, ITRError) {
        return ("", ITRError(code: 0, description: "Hello"))
    }
}
