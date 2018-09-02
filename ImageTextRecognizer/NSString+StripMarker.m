//
//  NSString+StripMarker.m
//  ImageTextRecognizer
//
//  Created by Tom Shen on 7/2/16.
//  Copyright © 2016 Tom and Jerry. All rights reserved.
//

#import "NSString+StripMarker.h"

@implementation NSString (StripMarker)

- (NSString *)stringByStrippingMarkers {
    NSRange r;
    NSString *s = [self copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

@end
