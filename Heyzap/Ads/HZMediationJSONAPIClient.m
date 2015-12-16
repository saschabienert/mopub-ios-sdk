//
//  HZMediationJSONAPIClient.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationJSONAPIClient.h"
#import "HZMediationJSONRequestSerializer.h"

@implementation HZMediationJSONAPIClient

+ (instancetype)sharedClient {
    static HZMediationJSONAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[HZMediationJSONAPIClient alloc] initWithBaseURL:[NSURL URLWithString: kHZMediationAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.requestSerializer = [HZMediationJSONRequestSerializer serializer];
    }
    return self;
}

@end
