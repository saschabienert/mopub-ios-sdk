//
//  HZHeyzapIncentivizedAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/4/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZHeyzapIncentivizedAd : NSObject

/** Shows an incentivized video ad if one is available */
+ (void) show;

/**
 *  Fetches an incentivized video ad from Heyzap.
 *
 *  @param completion A block called when the video is fetched or fails to fetch. `result` states whether the fetch was sucessful; the error object describes the issue, if there was one.
 */
+ (void) fetchWithCompletion: (void (^)(BOOL result, NSError *error))completion;

/**
 *  Whether or not a video ad is ready to show
 *
 *  @return If the video is ready to show
 */
+ (BOOL) isAvailable;

/**
 *  (Optional) As a layer of added security, you can specify an identifier for the user. You can opt to receive a server-to-server callback with the provided userIdentifier.
 *
 *  @param userIdentifier Any unique identifier, like a username, email, or ID that your server-side database uses.
 */
+ (void) setUserIdentifier: (NSString *) userIdentifier;


+ (void) setCreativeID: (int) creativeID;

@end
