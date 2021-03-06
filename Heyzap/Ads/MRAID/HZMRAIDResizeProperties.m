//
//  SKMRAIDResizeProperties.m
//  MRAID
//
//  Created by Jay Tucker on 9/16/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import "HZMRAIDResizeProperties.h"

@implementation HZMRAIDResizeProperties

- (id)init
{
    self = [super init];
    if (self) {
        _width = 0;
        _height = 0;
        _offsetX = 0;
        _offsetY = 0;
        _customClosePosition = HZMRAIDCustomClosePositionTopRight;
        _allowOffscreen = YES;
    }
    return self;
}

+ (HZMRAIDCustomClosePosition)MRAIDCustomClosePositionFromString:(NSString *)s
{
    NSArray *names = @[
                       @"top-left",
                       @"top-center",
                       @"top-right",
                       @"center",
                       @"bottom-left",
                       @"bottom-center",
                       @"bottom-right"
                       ];
    NSUInteger i = [names indexOfObject:s];
    if (i != NSNotFound) {
        return (HZMRAIDCustomClosePosition)i;
    }
    // Use top-right for the default value
    return HZMRAIDCustomClosePositionTopRight;;
}

@end
