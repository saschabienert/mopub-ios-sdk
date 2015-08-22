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
    
    
    context(@"When it's the test app", ^{
        it(@"Networks should always be enabled", ^{
            HZMediationPersistentConfig *config = [[HZMediationPersistentConfig alloc] initWithCachingService:cachingService isTestApp:NO];
            [config addDisabledNetwork:kNetworkName];
            
            [[theValue([config isNetworkEnabled:kNetworkName]) should] beTrue];
        });
    });
    
    context(@"When it's not the test app", ^{
        
        it(@"Should allow disabling networks", ^{
            [cachingService stub:@selector(rootObjectWithFilename:) andReturn:[NSSet set]];
            
            HZMediationPersistentConfig *config = [[HZMediationPersistentConfig alloc] initWithCachingService:cachingService isTestApp:YES];
            [[expectFutureValue(cachingService) shouldEventually] receive:@selector(cacheRootObject:filename:) withCount:2];
            
            [config addDisabledNetwork:kNetworkName];
            
            [[theValue([config isNetworkEnabled:kNetworkName]) should] beFalse];
            
            [config removeDisabledNetwork:kNetworkName];
            
            [[theValue([config isNetworkEnabled:kNetworkName]) should] beTrue];
            
        });
        
        it(@"Should load disabled networks from disk", ^{
            [cachingService stub:@selector(rootObjectWithFilename:) andReturn:[NSSet setWithObject:kNetworkName]];
            HZMediationPersistentConfig *config = [[HZMediationPersistentConfig alloc] initWithCachingService:cachingService isTestApp:YES];
            [[theValue([config isNetworkEnabled:kNetworkName]) should] beFalse];
        });
    });
    
});

SPEC_END
