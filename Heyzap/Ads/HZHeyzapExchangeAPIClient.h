//
//  HZHeyzapExchangeAPIClient.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HZAPIClient.h"

@interface HZHeyzapExchangeAPIClient : HZAPIClient

+ (HZHeyzapExchangeAPIClient *)sharedClient;

- (HZAFHTTPRequestOperation *)fetchAdWithExtraParams:(id)parameters success:(void (^)(HZAFHTTPRequestOperation *, id))success failure:(void (^)(HZAFHTTPRequestOperation *, NSError *))failure;

- (HZAFHTTPRequestOperation *)reportImpressionForAd:(NSString *)adId withExtraParams:(id)parameters success:(void (^)(HZAFHTTPRequestOperation *, id))success failure:(void (^)(HZAFHTTPRequestOperation *, NSError *))failure;

- (HZAFHTTPRequestOperation *)reportClickForAd:(NSString *)adId withExtraParams:(id)parameters success:(void (^)(HZAFHTTPRequestOperation *, id))success failure:(void (^)(HZAFHTTPRequestOperation *, NSError *))failure;

- (HZAFHTTPRequestOperation *)reportVideoCompletionForAd:(NSString *)adId withExtraParams:(id)parameters success:(void (^)(HZAFHTTPRequestOperation *, id))success failure:(void (^)(HZAFHTTPRequestOperation *, NSError *))failure;

@end
