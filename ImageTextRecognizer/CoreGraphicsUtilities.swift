//
//  CoreGraphicsUtilities.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 7/18/16.
//  Copyright © 2016 Tom and Jerry. All rights reserved.
//

import CoreGraphics

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func *=(point: inout CGPoint, scalar: CGFloat) {
    point = point * scalar
}

func *(size: CGSize, scalar: CGFloat) -> CGSize {
    return CGSize(width: size.width * scalar, height: size.height * scalar)
}

func *=(size: inout CGSize, scalar: CGFloat) {
    size = size * scalar
}
