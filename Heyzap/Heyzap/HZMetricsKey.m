//
//  HZMetricsKey.m
//  Heyzap
//
//  Created by Maximilian Tagher on 8/18/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMetricsKey.h"

@interface HZMetricsKey()

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *adType;

@end

@implementation HZMetricsKey

- (instancetype)initWithTag:(NSString *)tag type:(NSString *)adType
{
    NSParameterAssert(tag);
    NSParameterAssert(adType);
    
    self = [super init];
    if (self) {
        _tag = tag;
        _adType = adType;
    }
    return self;
}

// Referenced these blog posts for this section
// https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
// https://mikeash.com/pyblog/friday-qa-2010-08-27-defensive-programming-in-cocoa.html
#pragma mark - Equality / Hashing

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    HZMetricsKey *other = object;
    return [other.tag isEqualToString:self.tag]
        && [other.adType isEqualToString:self.adType];
}

- (NSUInteger)hash
{
    return self.tag.hash ^ self.adType.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return self; // HZMetricsKey is immutable; we can safely return ourselves.
}

#pragma mark - Utility

- (NSString *)description
{
    return [NSString stringWithFormat:@"HZMetricsKey - tag = %@ adType = %@",
            self.tag,self.adType];
}

@end
