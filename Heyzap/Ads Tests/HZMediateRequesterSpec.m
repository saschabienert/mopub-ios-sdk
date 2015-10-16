//
//  HZMediateRequesterSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/29/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZMediateRequester.h"
#import "OHHTTPStubs+Heyzap.h"
#import "HZCachingService.h"
#import "HZAdsManager.h"

@interface HZAdsManager(Testing)

+ (void)runInitialTasks;

@end

@interface HZMediateRequester (Testing)

@property (nonatomic) NSTimeInterval mediateRequestDelay;

@end


SPEC_BEGIN(HZMediateRequesterSpec)

describe(@"HZMediateRequester", ^{
    __block id requesterDelegate;
    __block HZCachingService *cachingMock;
    __block HZMediateRequester *requester;
    
    beforeAll(^{
        [HZAdsManager stub:@selector(runInitialTasks)]; // ProcessInfo, install reporting, etc. causes problems
    });
    
    beforeEach(^{
        requesterDelegate = [KWMock mockForProtocol:@protocol(HZMediateRequesterDelegate)];
        cachingMock = [KWMock nullMockForClass:[HZCachingService class]];
        
        [cachingMock stub:@selector(cacheRootObject:filename:) andReturn:nil];
        
        requester = [[HZMediateRequester alloc] initWithDelegate:requesterDelegate cachingService:cachingMock];
    });
    
    afterEach(^{
        [OHHTTPStubs removeAllStubs];
    });
    
    it(@"The requester should ping its delegate after updating mediate", ^{
        NSDictionary *const fromNetworkJson = @{@"foo": @"2423432423"};
        [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:fromNetworkJson];
        
        [[expectFutureValue(requesterDelegate) hzShouldEventuallyAfterDelay] receive:@selector(requesterUpdatedMediate)];
        [[expectFutureValue(cachingMock) hzShouldEventuallyAfterDelay] receive:@selector(cacheRootObject:filename:) withArguments:fromNetworkJson,any()];
        
        [requester start];
        
    });
    
    it(@"Should fallback to the cached version", ^{
        NSDictionary *const fromCacheJson = @{@"from_cache": @YES};
        NSDictionary *const fromNetworkJson = @{@"foo": @"2423432423"};
        
        // Initially make the request fail.
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.absoluteString hzContainsString:@"med.heyzap.com/mediate"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{}
                                                    statusCode:500
                                                       headers:nil];
        }];
        
        // 0.3 seconds later make it succeed
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:fromNetworkJson];
        });
        
        // To keep tests quick, rapidly retry.
        requester.mediateRequestDelay = 0.1;
        
        [[expectFutureValue(cachingMock) hzShouldEventuallyAfterDelay] receive:@selector(cacheRootObject:filename:) withArguments:fromNetworkJson,any()];
        
        [[expectFutureValue(cachingMock) hzShouldEventuallyAfterDelay] receive:@selector(rootObjectWithFilename:) andReturn:fromCacheJson withCountAtLeast:1];
        
        [[expectFutureValue(requesterDelegate) hzShouldEventuallyAfterDelay] receive:@selector(requesterUpdatedMediate) withCountAtLeast:2];
        
        [[expectFutureValue(cachingMock) hzShouldEventuallyAfterDelay] receive:@selector(cacheRootObject:filename:) withArguments:fromNetworkJson,any()];
        
        [requester start];
    });
    
    it(@"Returns the data from the network, even if the network is initially down",^{
        NSDictionary *const fromNetworkJson = @{@"foo": @"2423432423"};
        
        // Initially make the request fail.
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.absoluteString hzContainsString:@"med.heyzap.com/mediate"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{}
                                                    statusCode:500
                                                       headers:nil];
        }];
        
        // 0.3 seconds later make it succeed
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:fromNetworkJson];
        });
        
        // To keep tests quick, rapidly retry.
        requester.mediateRequestDelay = 0.1;
        
        [[expectFutureValue(requesterDelegate) hzShouldEventuallyAfterDelay] receive:@selector(requesterUpdatedMediate)];
        [[expectFutureValue(cachingMock) hzShouldEventuallyAfterDelay] receive:@selector(cacheRootObject:filename:) withCount:2];
        
        [requester start];
    });
    
});

SPEC_END
