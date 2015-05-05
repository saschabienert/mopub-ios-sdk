//
//  HZMediationRequestSerializer.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationRequestSerializer.h"
#import "HeyzapMediation.h"

@implementation HZMediationRequestSerializer

+ (NSMutableDictionary *)defaultParams {
    NSMutableDictionary *defaults = [super defaultParams];
    
    static NSDictionary *mediationDefaults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediationDefaults = @{
                              @"external_package":[[NSBundle mainBundle] bundleIdentifier],
                              @"networks":[HeyzapMediation commaSeparatedAdapterList],
                              };
    });
    
    [defaults addEntriesFromDictionary:mediationDefaults];
    
    return defaults;
}


@end
