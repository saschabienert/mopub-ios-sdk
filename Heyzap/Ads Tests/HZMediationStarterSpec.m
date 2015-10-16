//
//  HZMediationStarterSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/27/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZMediationStarter.h"
#import "HZDevice.h"
#import "HZUtils.h"
#import "HZCachingService.h"

@interface HZMediationStarter (Testing)

@property (nonatomic) NSTimeInterval retryStartDelay;

@end

SPEC_BEGIN(HZMediationStarterSpec)

describe(@"HZMediationStarter", ^{
    
    __block id starterMock;
    __block HZCachingService *cachingMock;
    __block HZMediationStarter *starter;

    beforeEach(^{
        starterMock = [KWMock mockForProtocol:@protocol(HZMediationStarting)];
        cachingMock = [KWMock nullMockForClass:[HZCachingService class]];
        
        [cachingMock stub:@selector(cacheRootObject:filename:) andReturn:nil];
        
        starter = [[HZMediationStarter alloc] initWithStartingDelegate:starterMock cachingService:cachingMock];
    });
    
    afterEach(^{
        [OHHTTPStubs removeAllStubs];
    });
    
    it(@"Returns the data from network when no cached value, then updates the cache", ^{
        NSDictionary *const fromNetworkJson = @{@"foo": @"2423432423"};
        [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:fromNetworkJson];
        
        [starter start];
        [[expectFutureValue(starterMock) shouldEventually] receive:@selector(startWithDictionary:fromCache:) withArguments:fromNetworkJson,theValue(NO)];
        [[expectFutureValue(starterMock) shouldEventually] receive:@selector(receivedStartHeaders:) withArguments:any()];
        
        [[expectFutureValue(cachingMock) shouldEventually] receive:@selector(cacheRootObject:filename:) withArguments:fromNetworkJson,any()];
    });
    
    it(@"Returns the cached version, then the network one, then updates the cache",^{
        NSDictionary *const fromCacheJson = @{@"from_cache": @YES};
        NSDictionary *const fromNetworkJson = @{@"from_network": @YES};
        
        [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:fromNetworkJson];
        
        [[cachingMock should] receive:@selector(rootObjectWithFilename:) andReturn:fromCacheJson];
        
        [[expectFutureValue(starterMock) shouldEventually] receive:@selector(receivedStartHeaders:) withArguments:any()];
        
        [starter start];
        [[expectFutureValue(starterMock) shouldEventually] receive:@selector(startWithDictionary:fromCache:) withArguments:fromCacheJson,theValue(YES)];
        [[expectFutureValue(starterMock) shouldEventually] receive:@selector(startWithDictionary:fromCache:) withArguments:fromNetworkJson,theValue(NO)];
        
        [[expectFutureValue(cachingMock) shouldEventually] receive:@selector(cacheRootObject:filename:) withArguments:fromNetworkJson,any()];
    });
    
    it(@"Returns the data from network, even if the network is initially down", ^{
        NSDictionary *const fromNetworkJson = @{@"foo": @"2423432423"};
        
        // Initially make the request fail.
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.absoluteString hzContainsString:@"med.heyzap.com/start"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{}
                                                    statusCode:500
                                                       headers:nil];
        }];
        
        // 0.3 seconds later make it succeed
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:fromNetworkJson];
        });
        
        // To keep tests quick, rapidly retry.
        starter.retryStartDelay = 0.1;
        
        [starter start];
        [[expectFutureValue(starterMock) shouldEventuallyBeforeTimingOutAfter(2)] receive:@selector(startWithDictionary:fromCache:) withArguments:fromNetworkJson,theValue(NO)];
        [[expectFutureValue(starterMock) shouldEventually] receive:@selector(receivedStartHeaders:)];
        
        [[expectFutureValue(cachingMock) shouldEventually] receive:@selector(cacheRootObject:filename:) withArguments:fromNetworkJson,any()];
    });
    
    
});

SPEC_END
