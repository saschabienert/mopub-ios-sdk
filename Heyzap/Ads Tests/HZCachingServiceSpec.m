//
//  HZCachingServiceSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/28/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZCachingService.h"
#import "HZUtils.h"


SPEC_BEGIN(HZCachingServiceSpec)

describe(@"HZCachingService", ^{
    
    NSString *const filename = @"foo.plist";
    
    beforeAll(^{
        [HZUtils createCacheDirectory];
    });
    
    __block HZCachingService *cachingService;
    beforeEach(^{
        cachingService = [[HZCachingService alloc] init];
    });
    
    afterEach(^{
        [[NSFileManager defaultManager] removeItemAtURL:[cachingService cacheUrlForFilename:filename] error:nil];
    });
    
    it(@"Reads what it writes", ^{
        NSDictionary *const dictionary = @{@"foo":@"bar"};
        [cachingService cacheRootObject:dictionary filename:filename];
        
        [[dictionary should] equal:[cachingService rootObjectWithFilename:filename]];
    });
});

SPEC_END
