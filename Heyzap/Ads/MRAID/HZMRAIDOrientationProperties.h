//
//  SKMRAIDOrientationProperties.h
//  MRAID
//
//  Created by Jay Tucker on 9/16/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HZMRAIDForceOrientationPortrait,
    HZMRAIDForceOrientationLandscape,
    HZMRAIDForceOrientationNone
} HZMRAIDForceOrientation;

@interface HZMRAIDOrientationProperties : NSObject

@property (nonatomic, assign) BOOL allowOrientationChange;
@property (nonatomic, assign) HZMRAIDForceOrientation forceOrientation;

+ (HZMRAIDForceOrientation)MRAIDForceOrientationFromString:(NSString *)s;

@end
