//
//  HZAdsAPIClient.m
//  Heyzap
//
//  Created by Daniel Rhodes on 8/13/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdsAPIClient.h"

NSString *const kHZRegisterImpressionEndpoint = @"register_impression";
NSString *const kHZRegisterClickEndpoint = @"register_click";

static NSString * const kHZAdsAPIBaseURLString = @"https://ads.heyzap.com/in_game_api/ads/";

@implementation HZAdsAPIClient

- (void) loadRequest: (HZAdFetchRequest *)request withCompletion: (void (^)(HZAdFetchRequest *request))completion {
    
    [self get: @"fetch_ad" withParams: request.params success:^(id JSON) {
        
        request.lastResponse = JSON;
        request.lastError = nil;
        request.rejectedImpressionID = nil;
        request.alreadyInstalledGame = nil;
        
        if (completion) {
            completion(request);
        }
        
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        
        request.lastFailingStatusCode = operation.response.statusCode;
        request.lastResponse = nil;
        request.lastError = error;
        
        if (completion) {
            completion(request);
        }
    }];
}

+ (HZAdsAPIClient *)sharedClient {
    static HZAdsAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[HZAdsAPIClient alloc] initWithBaseURL:[NSURL URLWithString: kHZAdsAPIBaseURLString]];
    });
    
    return _sharedClient;
}

@end