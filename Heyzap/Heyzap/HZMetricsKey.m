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
@property (nonatomic) NSString *adUnit;

@end

@implementation HZMetricsKey

- (instancetype)initWithTag:(NSString *)tag adUnit:(NSString *)adUnit network:(NSString *)network
{
    HZParameterAssert(tag);
    HZParameterAssert(adUnit);
    HZParameterAssert(network);
    
    self = [super init];
    if (self) {
        _tag = tag;
        _adUnit = adUnit;
        _network = network;
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
        && [other.adUnit isEqualToString:self.adUnit]
        && [other.network isEqualToString:self.network];
}

- (NSUInteger)hash
{
    return self.tag.hash ^ self.adUnit.hash ^ self.network.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return self; // HZMetricsKey is immutable; we can safely return ourselves.
}

#pragma mark - Utility

- (NSString *)description
{
    return [NSString stringWithFormat:@"HZMetricsKey - tag = %@ adUnit = %@ network = %@",
            self.tag,self.adUnit,self.network];
}

@end
