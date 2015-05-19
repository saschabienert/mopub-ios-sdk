//
//  HZNSURLUtils.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/5/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZNSURLUtils : NSObject

/**
 *  Substitutes placeholder values like {IDFA} with their appropriate values. You *must* run this on click URLs before trying to create `NSURL` values, otherwise the URL will be invalid and will be `nil`.
 *
 *  @param urlString    A string value of the URL to replace values in.
 *  @param impressionID The impression ID for the ad.
 *
 *  @return A URL without {placeholders}.
 */
+ (NSString *)substituteGetParams:(NSString *)urlString impressionID:(NSString *)impressionID;

extern NSMutableString * hzReplaceSubstringWithString(NSMutableString *mutableString, NSString *subtring, NSString *replacement);

@end
