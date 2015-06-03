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
@property (nonatomic) HZAdState adState;

@end

@implementation HZMediationSessionKey

- (instancetype)initWithAdType:(HZAdType)type tag:(NSString *)tag
{
    self = [super init];
    if (self) {
        _tag = tag;
        _adType = type;
        _adState = HZAdStateLoading;
    }
    return self;
}

- (instancetype)sessionKeyAfterRequestingShow {
    if (self.adState != HZAdStateLoading) {
        HZELog(@"Invalid state transition in HZMediationSessionKey from %@ in %@",NSStringFromHZAdState(self.adState),NSStringFromSelector(_cmd));
    }
    HZMediationSessionKey *copy = [self copy];
    copy.adState = HZAdStateRequestedShow;
    return copy;
}
- (instancetype)sessionKeyAfterShown {
    if (self.adState != HZAdStateRequestedShow) {
        HZELog(@"Invalid state transition in HZMediationSessionKey from %@ in %@",NSStringFromHZAdState(self.adState),NSStringFromSelector(_cmd));
    }
    HZMediationSessionKey *copy = [self copy];
    copy.adState = HZAdStateShown;
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
        && self.adState == session.adState;
    }
    return [super isEqual:object];
}

- (NSUInteger)hash
{
    return [self.tag hash] ^ self.adType ^ self.adState;
}

#pragma mark - NSCopying

- (id)copyWithZone: (NSZone *)zone
{
    HZMediationSessionKey *newObj = [[[self class] alloc] init];
    newObj.tag = self.tag;
    newObj.adType = self.adType;
    newObj.adState = self.adState;
    return newObj;
}

#pragma mark - Utility

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"MediationKey - tag = %@ adType = %@ adState = %@",
            self.tag,@(self.adType),NSStringFromHZAdState(self.adState)];
}

NSString *NSStringFromHZAdState(HZAdState state) {
    switch (state) {
        case HZAdStateLoading: {
            return @"HZAdStateLoading";
        }
        case HZAdStateRequestedShow: {
            return @"HZAdStateRequestedShow";
        }
        case HZAdStateShown: {
            return @"HZAdStateShown";
        }
    }
}

@end
