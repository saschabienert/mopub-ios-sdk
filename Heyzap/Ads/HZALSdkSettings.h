//
//  HZALSdkSettings.h
//  Heyzap
//
//  Created by Monroe Ekilah on 9/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZALAdService;

@interface HZALSdkSettings : HZClassProxy

- (instancetype)init;

@property (assign, atomic) BOOL isVerboseLogging;

/**
 * Defines sizes of ads that should be automatically preloaded.
 * <p>
 * Auto preloading is enabled for <code>BANNER,INTER</code> by default.
 * To disable outright, set to "NONE".
 *
 * @param autoPreloadAdSizes Comma-separated list of sizes to preload. For example: "BANNER,INTER"
 */
@property (strong, atomic) NSString*  autoPreloadAdSizes;

/**
 * Defines types of ads that should be automatically preloaded.
 * <p>
 * Auto preloading is enabled for <code>REGULAR,INCENTIVIZED</code> by default.
 * To disable outright, set to "NONE".
 *
 * @param autoPreloadAdSizes Comma-separated list of sizes to preload. For example: "REGULAR,INCENTIVIZED"
 */
@property (strong, atomic) NSString*  autoPreloadAdTypes;

@end
