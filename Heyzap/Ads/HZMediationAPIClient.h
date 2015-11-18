//
//  MicahClient.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/28/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAPIClient.h"

extern NSString * const kHZMediationAPIBaseURLString;

@interface HZMediationAPIClient : HZAPIClient

+ (instancetype)sharedClient;

@end
