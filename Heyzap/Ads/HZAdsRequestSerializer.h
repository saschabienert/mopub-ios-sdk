//
//  HZAdsRequestSerializer.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZAFURLRequestSerialization.h"

@interface HZAdsRequestSerializer : HZAFHTTPRequestSerializer

// Subclasses may override.
+ (NSMutableDictionary *)defaultParams;

@end
