//
//  DeviceIdentifier.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 2/15/17.
//  Copyright © 2017 Tom and Jerry. All rights reserved.
//

import UIKit

extension UIDevice {
    func identifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
