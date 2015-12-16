//
//  MicahClient.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/28/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMediationAPIClient.h"
#import "HeyzapMediation.h"
#import "HZMediationRequestSerializer.h"

NSString * const kHZMediationAPIBaseURLString = @"https://med.heyzap.com/";

@implementation HZMediationAPIClient

+ (instancetype)sharedClient {
    static HZMediationAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[HZMediationAPIClient alloc] initWithBaseURL:[NSURL URLWithString: kHZMediationAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.requestSerializer = [HZMediationRequestSerializer serializer];
    }
    return self;
}

@end
