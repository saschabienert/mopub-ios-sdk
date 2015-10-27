//
//  TestJSON.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "TestJSON.h"

@implementation TestJSON

+ (NSMutableDictionary *)portraitInterstitialJSON
{
    return [self jsonForResource:@"portraitInterstitialRequest"];
}

+ (NSMutableDictionary *)nativeAdJSON {
    return [self jsonForResource:@"ValidNativeAd"];
}

+ (NSMutableDictionary *)mediationStartJSONThatShouldProduceFiveSegments {
    return [self jsonForResource:@"mediationStartResponseThatShouldProduceFiveSegments"];
}

+ (NSMutableDictionary *)jsonForResource:(NSString *)resource
{
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:resource withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    NSError *error;
    NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error];
    
    NSAssert(error == nil, @"Error should be nil");
    NSAssert(json, @"JSON shouldn't be nil");
    
    return json;
}

@end
