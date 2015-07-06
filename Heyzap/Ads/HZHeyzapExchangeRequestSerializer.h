//
//  HZHeyzapExchangeRequestSerializer.h
//  Heyzap
//
//  Created by Monroe Ekilah on 7/1/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZAFURLRequestSerialization.h"

@interface HZHeyzapExchangeRequestSerializer : HZAFHTTPRequestSerializer

// Subclasses may override.
+ (NSMutableDictionary *)defaultParams;

@end
