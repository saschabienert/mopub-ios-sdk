//
//  HZVungleAdapterSpecSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/22/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZVungleAdapter.h"

@interface HZVungleAdapter (Tests)

+ (NSString *)vungleValidPlacementCharacters;
+ (NSString *)sanitizeAdTagForVunglePlacement:(NSString *)tag;

@end

SPEC_BEGIN(HZVungleAdapterSpec)

describe(@"HZVungleAdapterSpec", ^{
    context(@"Vungle placements", ^{
        it(@"Valid characters are left unchanged", ^{
           NSString *validCharacters = [HZVungleAdapter vungleValidPlacementCharacters];
           NSString *sanitized = [HZVungleAdapter sanitizeAdTagForVunglePlacement:validCharacters];
           [[validCharacters should] equal:sanitized];
        });
        
        it(@"Valid characters are left unchanged 2", ^{
            NSString *const valid = @"fooBarBaz12-_";
            [[[HZVungleAdapter sanitizeAdTagForVunglePlacement:valid] should] equal:valid];
        });
        
        it(@"Invalid characters should be removed", ^{
            NSString *const string = @"foo!@#$%^&*()-_=+台北àãāBAR123";
            [[[HZVungleAdapter sanitizeAdTagForVunglePlacement:string] should] equal:@"foo-_BAR123"];
        });
    });
});

SPEC_END
