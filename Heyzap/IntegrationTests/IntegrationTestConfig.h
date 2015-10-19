//
//  IntegrationTestConfig.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/14/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IntegrationTestConfig : NSObject

@property (nonatomic, readonly, getter=shouldStubHTTPRequests) BOOL stubHTTPRequests;

+ (instancetype)sharedConfig;

@end
