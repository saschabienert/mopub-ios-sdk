//
//  IntegrationTestConfig.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/14/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "IntegrationTestConfig.h"

@implementation IntegrationTestConfig

+ (instancetype)sharedConfig {
    static IntegrationTestConfig *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[IntegrationTestConfig alloc] init];
    });
    return config;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _stubHTTPRequests = [@"true" isEqualToString:[NSProcessInfo processInfo].environment[@"STUB_HTTP_REQUESTS"]];
    }
    return self;
}

@end
