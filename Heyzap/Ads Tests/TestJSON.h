//
//  TestJSON.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestJSON : NSObject

/**
 *  JSON for the portrait fullscreen interstitial ad.
 *
 *  @return The dictionary, guaranteed to not be nil.
 */
+ (NSMutableDictionary *)portraitInterstitialJSON;

@end
