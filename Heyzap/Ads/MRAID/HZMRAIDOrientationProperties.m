//
//  SKMRAIDOrientationProperties.m
//  MRAID
//
//  Created by Jay Tucker on 9/16/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import "HZMRAIDOrientationProperties.h"

NSString *HZNSStringFromMRAIDForceOrientation(HZMRAIDForceOrientation orientation) {
    switch (orientation) {
        case HZMRAIDForceOrientationPortrait:
            return @"HZMRAIDForceOrientationPortrait";
        case HZMRAIDForceOrientationLandscape:
            return @"HZMRAIDForceOrientationLandscape";
        case HZMRAIDForceOrientationNone:
            return @"HZMRAIDForceOrientationNone";
            break;
    }
}

@implementation HZMRAIDOrientationProperties

- (id)init
{
    self = [super init];
    if (self) {
        _allowOrientationChange = YES;
        _forceOrientation = HZMRAIDForceOrientationNone;
    }
    return self;
}

+ (HZMRAIDForceOrientation)MRAIDForceOrientationFromString:(NSString *)s
{
    NSArray *names = @[ @"portrait", @"landscape", @"none" ];
    NSUInteger i = [names indexOfObject:s];
    if (i != NSNotFound) {
        return (HZMRAIDForceOrientation)i;
    }
    // Use none for the default value
    return HZMRAIDForceOrientationNone;
}

@end
