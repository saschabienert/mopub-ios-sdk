//
//  HZUnityAbstractAdapter.m
//  Heyzap
//
//  Created by Mike Urbach on 4/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#if UNITY_IPHONE
extern void UnitySendMessage(const char *, const char *, const char *);
#endif

#import "HZUnityAbstractAdapter.h"

@implementation HZUnityAbstractAdapter

+ (void)sendMessage:(NSString *)msg fromNetwork:(NSString *)network {
#if UNITY_IPHONE
    NSString *message = [NSString stringWithFormat:@"%@ %@,%@", network, msg, @""];
    UnitySendMessage("HeyzapAds", "setAbstractDisplayState", [message UTF8String]);
#endif
}

@end
