//
//  HZCreativeType.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/19/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

typedef NSNumber HZCreativeTypeObject;

// This is a bitmasked parameter, but with the exception of the `supportedAdFormats` method, almost everything else should treat it as just an enum.
// These values match server values and should not be modified without a change on the server and other SDKs
typedef NS_OPTIONS(NSUInteger, HZCreativeType) {
    HZCreativeTypeUnknown       = 0,      // 0 (in some contexts, HZCreativeTypeUnknown represents an error condition. In others, it means "all creative types")
    HZCreativeTypeStatic        = 1 << 0, // 1
    HZCreativeTypeVideo         = 1 << 1, // 2
    HZCreativeTypeIncentivized  = 1 << 2, // 4
    HZCreativeTypeBanner        = 1 << 3, // 8
    HZCreativeTypeNative        = 1 << 4  // 16
};



extern NSString * const hzCreativeTypeUnknownString;
extern NSString * const hzCreativeTypeStaticString;
extern NSString * const hzCreativeTypeVideoString;
extern NSString * const hzCreativeTypeIncentivizedString;
extern NSString * const hzCreativeTypeBannerString;
extern NSString * const hzCreativeTypeNativeString;

BOOL hzCreativeTypeStringSetContainsCreativeType(NSSet *const creativeTypes, const HZCreativeType creativeType);
/**
 *  Synonym for `hzCreativeTypeFromNSNumber`
 *
 *  @param object The wrapped creative type
 *
 *  @return The unwrapped `HZCreativeType`
 */
HZCreativeType hzCreativeTypeFromObject(HZCreativeTypeObject *object);
HZCreativeType hzCreativeTypeFromNSNumber(NSNumber * number);
HZCreativeType hzCreativeTypeFromString(NSString *creativeTypeString);
NSString * NSStringFromCreativeType(HZCreativeType creativeType);