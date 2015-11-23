//
//  HZGADAdLoader.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@protocol HZGADAdLoaderDelegate;

@interface HZGADAdLoader : HZClassProxy

@property(nonatomic, weak) id<HZGADAdLoaderDelegate> delegate;

/// Returns an initialized ad loader configured to load the specified ad types.
///
/// @param rootViewController The root view controller is used to present ad click actions. Cannot
/// be nil.
/// @param adTypes An array of ad types. See GADAdLoaderAdTypes.h for available ad types.
/// @param options An array of GADAdLoaderOptions objects to configure how ads are loaded, or nil to
/// use default options. See each ad type's header for available GADAdLoaderOptions subclasses.
- (instancetype)initWithAdUnitID:(NSString *)adUnitID
              rootViewController:(UIViewController *)rootViewController
                         adTypes:(NSArray *)adTypes
                         options:(NSArray *)options;

/// Loads the ad and informs the delegate of the outcome.
- (void)loadRequest:(HZGADRequest *)request;

@end
