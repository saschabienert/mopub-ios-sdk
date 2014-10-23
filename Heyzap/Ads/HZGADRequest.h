//
//  HZGADRequest.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

#define GAD_SIMULATOR_ID @"Simulator"

@interface HZGADRequest : HZClassProxy

@property(nonatomic, copy) NSArray *testDevices;

+ (HZGADRequest *)request;

+ (NSString *)sdkVersion;

@end
