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

@property (nonatomic, strong) NSString *tag;
@property (nonatomic) HZAdType adType;
@property (nonatomic) BOOL hasBeenShown;

@end

@implementation HZMediationSessionKey

- (instancetype)initWithAdType:(HZAdType)type tag:(NSString *)tag
{
    self = [super init];
    if (self) {
        _tag = tag;
        _adType = type;
        _hasBeenShown = NO;
    }
    return self;
}

- (instancetype)sessionKeyAfterShowing
{
    HZMediationSessionKey *copy = [self copy];
    copy.hasBeenShown = YES;
    return copy;
}

// Referenced these blog posts for this section
// https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
// https://mikeash.com/pyblog/friday-qa-2010-08-27-defensive-programming-in-cocoa.html
#pragma mark - Equality / Hashing

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[HZMediationSessionKey class]]) {
        HZMediationSessionKey *session = object;
        return [self.tag isEqualToString:session.tag]
        && self.adType == session.adType
        && self.hasBeenShown == session.hasBeenShown;
    }
    return [super isEqual:object];
}

- (NSUInteger)hash
{
    return [self.tag hash] ^ self.adType ^ self.hasBeenShown;
}

#pragma mark - NSCopying

- (id)copyWithZone: (NSZone *)zone
{
    HZMediationSessionKey *newObj = [[[self class] alloc] init];
    newObj.tag = self.tag;
    newObj.adType = self.adType;
    newObj.hasBeenShown = self.hasBeenShown;
    return newObj;
}

#pragma mark - Utility

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"MediationKey - tag = %@ adType = %i beenShown = %i",self.tag,self.adType,self.hasBeenShown];
}

@end
