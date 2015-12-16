//
//  HZCreativeType.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/21/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZCreativeType.h"

NSString * const hzCreativeTypeUnknownString = @"UNKNOWN";
NSString * const hzCreativeTypeStaticString = @"STATIC";
NSString * const hzCreativeTypeVideoString = @"VIDEO";
NSString * const hzCreativeTypeIncentivizedString = @"INCENTIVIZED";
NSString * const hzCreativeTypeBannerString = @"BANNER";
NSString * const hzCreativeTypeNativeString = @"NATIVE";

BOOL hzCreativeTypeStringSetContainsCreativeType(NSSet *const creativeTypes, const HZCreativeType creativeType) {
    return [creativeTypes containsObject:NSStringFromCreativeType(creativeType)];
}

HZCreativeType hzCreativeTypeFromObject(HZCreativeTypeObject *object) {
    return hzCreativeTypeFromNSNumber(object);
}

HZCreativeType hzCreativeTypeFromNSNumber(HZCreativeTypeObject * number) {
    NSUInteger num = [number unsignedIntegerValue];
    switch (num) {
        case ((NSUInteger)HZCreativeTypeStatic):
            return HZCreativeTypeStatic;
        case ((NSUInteger)HZCreativeTypeVideo):
            return HZCreativeTypeVideo;
        case ((NSUInteger)HZCreativeTypeIncentivized):
            return HZCreativeTypeIncentivized;
        case ((NSUInteger)HZCreativeTypeBanner):
            return HZCreativeTypeBanner;
        case ((NSUInteger)HZCreativeTypeNative):
            return HZCreativeTypeNative;
        default:
            return HZCreativeTypeUnknown;
    }
}

HZCreativeType hzCreativeTypeFromString(NSString *creativeTypeString) {
    if([creativeTypeString isEqualToString:hzCreativeTypeStaticString]){
        return HZCreativeTypeStatic;
    }
    if([creativeTypeString isEqualToString:hzCreativeTypeVideoString]){
        return HZCreativeTypeVideo;
    }
    if([creativeTypeString isEqualToString:hzCreativeTypeIncentivizedString]){
        return HZCreativeTypeIncentivized;
    }
    if([creativeTypeString isEqualToString:hzCreativeTypeBannerString]){
        return HZCreativeTypeBanner;
    }
    if([creativeTypeString isEqualToString:hzCreativeTypeNativeString]){
        return HZCreativeTypeNative;
    }
    
    return HZCreativeTypeUnknown;
}

NSString * NSStringFromCreativeType(HZCreativeType creativeType) {
    switch(creativeType) {
        case HZCreativeTypeUnknown:
            return hzCreativeTypeUnknownString;
        case HZCreativeTypeStatic:
            return hzCreativeTypeStaticString;
        case HZCreativeTypeVideo:
            return hzCreativeTypeVideoString;
        case HZCreativeTypeIncentivized:
            return hzCreativeTypeIncentivizedString;
        case HZCreativeTypeBanner:
            return hzCreativeTypeBannerString;
        case HZCreativeTypeNative:
            return hzCreativeTypeNativeString;
    }
}