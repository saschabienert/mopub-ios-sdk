//
//  HZAdsAPIClient.h
//  Heyzap
//
//  Created by Daniel Rhodes on 8/13/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAPIClient.h"
#import "HZAdFetchRequest.h"

@interface HZAdsAPIClient : HZAPIClient

- (void) loadRequest: (HZAdFetchRequest *)request withCompletion: (void (^)(HZAdFetchRequest *request))completion;
+ (HZAdsAPIClient *)sharedClient;

@end
