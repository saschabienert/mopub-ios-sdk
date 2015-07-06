//
//  HZHeyzapExchangeAPIClient.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeAPIClient.h"
#import "HZAFURLResponseSerialization.h"
#import "HZHeyzapExchangeRequestSerializer.h"

NSString * const kHZHeyzapExchangeAPIBaseURLString = @"http://x.heyzap.com/"; // monroe: change from test endpoint later. also: https? certs are broken right now

@implementation HZHeyzapExchangeAPIClient

+ (HZHeyzapExchangeAPIClient *)sharedClient {
    static HZHeyzapExchangeAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[HZHeyzapExchangeAPIClient alloc] initWithBaseURL:[NSURL URLWithString: kHZHeyzapExchangeAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.requestSerializer = [HZHeyzapExchangeRequestSerializer serializer];
        self.responseSerializer = [[HZAFHTTPResponseSerializer alloc] init];
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    }
    return self;
}

- (HZAFHTTPRequestOperation *)fetchAdWithExtraParams:(id)parameters success:(void (^)(HZAFHTTPRequestOperation *, id))success failure:(void (^)(HZAFHTTPRequestOperation *, NSError *))failure {
    return [self GET:@"_/0/ad" parameters:parameters success:success failure:failure];
}

- (HZAFHTTPRequestOperation *)reportClickForAd:(NSString *)adId withExtraParams:(id)parameters success:(void (^)(HZAFHTTPRequestOperation *, id))success failure:(void (^)(HZAFHTTPRequestOperation *, NSError *))failure {
    return [self GET:[NSString stringWithFormat:@"_/0/ad/%@/click", adId] parameters:parameters success:success failure:failure];
}

- (HZAFHTTPRequestOperation *)reportImpressionForAd:(NSString *)adId withExtraParams:(id)parameters success:(void (^)(HZAFHTTPRequestOperation *, id))success failure:(void (^)(HZAFHTTPRequestOperation *, NSError *))failure {
    return [self POST:[NSString stringWithFormat:@"_/0/ad/%@/impression", adId] parameters:parameters success:success failure:failure];
}

- (HZAFHTTPRequestOperation *)reportVideoCompletionForAd:(NSString *)adId withExtraParams:(id)parameters success:(void (^)(HZAFHTTPRequestOperation *, id))success failure:(void (^)(HZAFHTTPRequestOperation *, NSError *))failure {
    return [self GET:[NSString stringWithFormat:@"_/0/ad/%@/complete", adId] parameters:parameters success:success failure:failure];
}


@end
