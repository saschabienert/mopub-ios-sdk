//
//  VASTSettings.m
//  VAST
//
//  Created by Muthu on 6/26/14.
//  Copyright (c) 2014 Nexage, Inc. All rights reserved.
//

#import "HZVASTSettings.h"

const NSString* kHZVASTKitVersion     = @"1.0.6";
int const kHZMaxRecursiveDepth = 5;
float const kHZPlayTimeCounterInterval = 0.25; // time interval between each check for video play duration (for callbacks related to how long a video was watched)
BOOL const kHZValidateWithSchema = NO; // whether or not to use HZvast_2.0.1.xsd to validate incoming XML

@implementation HZVASTSettings

@end