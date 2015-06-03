//
//  HZExtendedHitAreaButton.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//
#import "HZExtendedHitAreaButton.h"

@implementation HZExtendedHitAreaButton

#define HZExtendedHitAreaButtonDefaultMarginX 20.0
#define HZExtendedHitAreaButtonDefaultMarginY 20.0

-(id)init {
    if (self = [super init])  {
        self.extendedHitAreaMarginX = HZExtendedHitAreaButtonDefaultMarginX;
        self.extendedHitAreaMarginY = HZExtendedHitAreaButtonDefaultMarginY;
    }
    return self;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // increase the hit area for the button
    CGRect area = CGRectInset(self.bounds, -self.extendedHitAreaMarginX, -self.extendedHitAreaMarginY);
    return CGRectContainsPoint(area, point);
}
@end