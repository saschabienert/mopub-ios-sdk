//
//  HZMediationPersistentConfigSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 8/21/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZMediationPersistentConfig.h"
#import "HZCachingService.h"


SPEC_BEGIN(HZMediationPersistentConfigSpec)

NSString * const kNetworkName = @"heyzap";

describe(@"HZMediationPersistentConfig", ^{
    
    __block HZCachingService *cachingService;
    beforeEach(^{
        cachingService = [KWMock nullMockForClass:[HZCachingService class]];
    });
    
    it(@"Should allow disabling networks", ^{
        [cachingService stub:@selector(rootObjectWithFilename:) andReturn:[NSSet set]];
        
        HZMediationPersistentConfig *config = [[HZMediationPersistentConfig alloc] initWithCachingService:cachingService];
        [[expectFutureValue(cachingService) hzShouldEventuallyAfterDelay] receive:@selector(cacheRootObject:filename:) withCountAtLeast:1];
        
        [config addDisabledNetwork:kNetworkName];
        
        [[theValue([config isNetworkEnabled:kNetworkName]) should] beFalse];
        
        [config removeDisabledNetwork:kNetworkName];
        
        [[theValue([config isNetworkEnabled:kNetworkName]) should] beTrue];
        
    });
    
    it(@"Should load disabled networks from disk", ^{
        [cachingService stub:@selector(rootObjectWithFilename:) andReturn:[NSSet setWithObject:kNetworkName]];
        HZMediationPersistentConfig *config = [[HZMediationPersistentConfig alloc] initWithCachingService:cachingService];
        [[theValue([config isNetworkEnabled:kNetworkName]) should] beFalse];
    });
    
});

SPEC_END
