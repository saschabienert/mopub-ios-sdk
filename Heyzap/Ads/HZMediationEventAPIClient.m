//
//  HZMediationEventAPIClient.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/17/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMediationEventAPIClient.h"

@implementation HZMediationEventAPIClient

NSString * const kHZMediationEventBaseURLString = @"https://event.med.heyzap.com/";

+ (HZMediationAPIClient *)sharedClient {
    static HZMediationAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedClient = [[HZMediationAPIClient alloc] initWithBaseURL:[NSURL URLWithString: kHZMediationEventBaseURLString]];
    });
    
    return _sharedClient;
}

@end
