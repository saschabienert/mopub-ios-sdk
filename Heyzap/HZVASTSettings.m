//
//  VASTSettings.m
//  VAST
//
//  Created by Muthu on 6/26/14.
//  Copyright (c) 2014 Nexage, Inc. All rights reserved.
//

#import "HZVASTSettings.h"

const NSString* kVASTKitVersion     = @"1.0.6";
int const kMaxRecursiveDepth = 5;
float const kPlayTimeCounterInterval = 0.25;
NSTimeInterval const kVideoLoadTimeoutInterval = 10.0;
NSTimeInterval const kFirstShowControlsDelay = 4.0; // hide controls for this many seconds at beginning of video
BOOL const kValidateWithSchema = YES; // whether or not to use HZvast_2.0.1.xsd to validate incoming XML

@implementation HZVASTSettings

static NSTimeInterval vastVideoLoadTimeout= kVideoLoadTimeoutInterval;

+ (NSTimeInterval)vastVideoLoadTimeout
{
    return vastVideoLoadTimeout?vastVideoLoadTimeout:kVideoLoadTimeoutInterval;
}

+ (void)setVastVideoLoadTimeout:(NSTimeInterval)newValue
{
    if (newValue!=vastVideoLoadTimeout) {
        vastVideoLoadTimeout = newValue>=kVideoLoadTimeoutInterval?newValue:kVideoLoadTimeoutInterval;  // force minimum to default value
    }
}

@end