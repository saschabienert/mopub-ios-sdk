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
float const kPlayTimeCounterInterval = 0.25; // time interval between each check for video play duration (for callbacks related to how long a video was watched)
BOOL const kValidateWithSchema = YES; // whether or not to use HZvast_2.0.1.xsd to validate incoming XML

@implementation HZVASTSettings

@end