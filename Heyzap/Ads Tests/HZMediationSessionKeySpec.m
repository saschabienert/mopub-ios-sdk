//
//  HZMediationSessionKeySpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/2/14.
//  Copyright 2014 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZMediationSessionKey.h"


SPEC_BEGIN(HZMediationSessionKeySpec)

describe(@"HZMediationSessionKey", ^{
    
    it(@"should correctly detect duplicate keys", ^{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        HZMediationSessionKey *key1 = [[HZMediationSessionKey alloc] initWithAdType:HZAdTypeIncentivized tag:@"default"];
        HZMediationSessionKey *key2 = [[HZMediationSessionKey alloc] initWithAdType:HZAdTypeIncentivized tag:@"default"];
        dict[key1] = @"";
        dict[key2] = @"";
        [[theValue(dict.allKeys.count) should] equal:@1];
        
        HZMediationSessionKey *key3 = [[HZMediationSessionKey alloc] initWithAdType:HZAdTypeVideo tag:@"vTag"];
        HZMediationSessionKey *key4 = [[HZMediationSessionKey alloc] initWithAdType:HZAdTypeVideo tag:@"vTag"];
        dict[key3] = @"";
        dict[key4] = @"";
        
        [[theValue(dict.allKeys.count) should] equal:@2];
        
        HZMediationSessionKey *key5 = [[HZMediationSessionKey alloc] initWithAdType:HZAdTypeInterstitial tag:@"default"];
        HZMediationSessionKey *key6 = [[HZMediationSessionKey alloc] initWithAdType:HZAdTypeInterstitial tag:@"hi"];
        dict[key5] = @"";
        dict[key6] = @"";
        
        [[theValue(dict.allKeys.count) should] equal:@4];
        
        HZMediationSessionKey *requestingShownKey = [key6 sessionKeyAfterRequestingShow];
        dict[requestingShownKey] = @"";
        
        [[theValue(dict.allKeys.count) should] equal:@5];
        
        HZMediationSessionKey *afterShownKey = [requestingShownKey sessionKeyAfterShown];
        dict[afterShownKey] = @"";
        
        [[theValue(dict.allKeys.count) should] equal:@6];
        
        [dict removeObjectForKey:key6];
        
        [[theValue(dict.allKeys.count) should] equal:@5];
    });

});

SPEC_END
