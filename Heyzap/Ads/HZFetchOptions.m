//
//  HZFetchOptions.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZFetchOptions.h"
#import "HZFetchOptions_HeyzapMediationPrivate.h"
#import "HeyzapAds.h"
#import "HZAdModel.h"
#import "HZMediationConstants.h"

@implementation HZFetchOptions

- (instancetype) init {
    self = [super init];
    if (self) {
        _creativeTypesToFetch = [NSSet new];
        _creativeTypesFetchesFinished= [NSSet new];
        _alreadyNotifiedDelegateOfSuccess = NO;
    }
    
    return self;
}

@synthesize tag = _tag;

- (NSString *)tag {
    if (_tag == nil) {
        _tag = [HeyzapAds defaultTagName];
    }
    
    return _tag;
}

- (void) setTag:(nullable NSString *)tag {
    _tag = [HZAdModel normalizeTag:tag];
}

- (id)copyWithZone:(NSZone *)zone {
    HZFetchOptions *copy = [[HZFetchOptions alloc] init];
    copy.tag = self.tag;
    copy.requestingAdType = self.requestingAdType;
    copy.additionalParameters = [[NSDictionary alloc] initWithDictionary:self.additionalParameters copyItems:NO];
    copy.completion = self.completion;
    copy.placementIDOverride = self.placementIDOverride;
    copy.alreadyNotifiedDelegateOfSuccess = self.alreadyNotifiedDelegateOfSuccess;
    copy.creativeTypesToFetch = [NSSet setWithSet:self.creativeTypesToFetch];
    copy.creativeTypesFetchesFinished = [NSSet setWithSet:self.creativeTypesFetchesFinished];
    return copy;
}

@end