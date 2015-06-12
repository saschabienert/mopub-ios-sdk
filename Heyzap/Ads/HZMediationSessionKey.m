//
//  HZMediationSession.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMediationSessionKey.h"
#import "HZBaseAdapter.h"

@interface HZMediationSessionKey()

@property (nonatomic) HZAdType adType;

@end

@implementation HZMediationSessionKey

- (instancetype)initWithAdType:(HZAdType)type
{
    self = [super init];
    if (self) {
        _adType = type;
    }
    return self;
}

// Referenced these blog posts for this section
// https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
// https://mikeash.com/pyblog/friday-qa-2010-08-27-defensive-programming-in-cocoa.html
#pragma mark - Equality / Hashing

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[HZMediationSessionKey class]]) {
        HZMediationSessionKey *session = object;
        return self.adType == session.adType;
    }
    return [super isEqual:object];
}

- (NSUInteger)hash
{
    return self.adType;
}

#pragma mark - NSCopying

- (id)copyWithZone: (NSZone *)zone
{
    HZMediationSessionKey *newObj = [[[self class] alloc] init];
    newObj.adType = self.adType;
    return newObj;
}

#pragma mark - Utility

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"MediationKey - adType = %@", @(self.adType)];
}

@end
