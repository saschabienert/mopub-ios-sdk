//
//  SKMRAIDResizeProperties.h
//  MRAID
//
//  Created by Jay Tucker on 9/16/13.
//  Copyright (c) 2013 Nexage, Inc. All Rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HZMRAIDCustomClosePositionTopLeft,
    MRAIDCustomClosePositionTopCenter,
    MRAIDCustomClosePositionTopRight,
    MRAIDCustomClosePositionCenter,
    MRAIDCustomClosePositionBottomLeft,
    MRAIDCustomClosePositionBottomCenter,
    MRAIDCustomClosePositionBottomRight
} HZMRAIDCustomClosePosition;

@interface HZMRAIDResizeProperties : NSObject

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int offsetX;
@property (nonatomic, assign) int offsetY;
@property (nonatomic, assign) HZMRAIDCustomClosePosition customClosePosition;
@property (nonatomic, assign) BOOL allowOffscreen;

+ (HZMRAIDCustomClosePosition)MRAIDCustomClosePositionFromString:(NSString *)s;

@end
