//
//  HZAdLibraryKey.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdInfo.h"

@implementation HZAdInfo

- (instancetype)initWithProvider:(id<HZAdInfoProvider>)provider {
    return [self initWithFetchableCreativeType:[provider fetchableCreativeType] auctionType:[provider auctionType]];
}

// Designated Initializer
- (instancetype)initWithFetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType
{
    self = [super init];
    if (self) {
        _fetchableCreativeType = fetchableCreativeType;
        _auctionType = auctionType;
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
    HZAdInfo *other = object;
    return other.fetchableCreativeType == self.fetchableCreativeType
    && other.auctionType == self.auctionType;
}

- (NSUInteger)hash
{
    return self.fetchableCreativeType ^ self.auctionType;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return self; // HZAdInfo is immutable; we can safely return ourselves.
}

#pragma mark - Utility

- (NSString *)description
{
    return [NSString stringWithFormat:@"HZAdInfo - fetchableCreativeType = %@ auctionType = %@",
            NSStringFromHZFetchableCreativeType(self.fetchableCreativeType), NSStringFromHZAuctionType(self.auctionType)];
}


@end
