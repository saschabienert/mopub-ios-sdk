//
//  HZNSURLUtilsSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/24/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZNSURLUtils.h"


SPEC_BEGIN(HZNSURLUtilsSpec)

describe(@"HZNSURLUtils", ^{
    
    context(@"Substitute get params", ^{
        it(@"Should replace the impression ID", ^{
            NSString *result= [HZNSURLUtils substituteGetParams:@"{IMPRESSION_ID}" impressionID:@"foo"];
            [[result should] equal:@"foo"];
        });
    });
    
    context(@"String replacement", ^{
        
        // Positive tests
        
        it(@"Should replace the substring", ^{
            NSMutableString *mutableString1 = [[NSMutableString alloc] initWithString:@"foobar"];
            hzReplaceSubstringWithString(mutableString1, @"bar", @"baz");
            NSMutableString *mutableString2 = [NSMutableString stringWithString:@"foobaz"];
            [[mutableString1 should] equal:mutableString2];
        });
        
        // Negative tests
        
        it(@"Shouldn't be case insensitive", ^{
            NSMutableString *mutableString1 = [[NSMutableString alloc] initWithString:@"foobar"];
            hzReplaceSubstringWithString(mutableString1, @"BAR", @"baz");
            NSMutableString *mutableString2 = [NSMutableString stringWithString:@"foobar"];
            [[mutableString1 should] equal:mutableString2];
        });
        
        it(@"Shouldn't replace a non-matching string", ^{
            NSMutableString *mutableString1 = [[NSMutableString alloc] initWithString:@"foobar"];
            hzReplaceSubstringWithString(mutableString1, @"qux", @"baz");
            NSMutableString *mutableString2 = [NSMutableString stringWithString:@"foobar"];
            [[mutableString1 should] equal:mutableString2];
        });
        
        
    });
});

SPEC_END
