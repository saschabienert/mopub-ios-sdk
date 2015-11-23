//
//  HZGADNativeAppInstallAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZGADNativeAdImage;

@interface HZGADNativeAppInstallAd : HZClassProxy

#pragma mark - Must be displayed

/// App title.
@property(nonatomic, readonly, copy) NSString *headline;
/// Text that encourages user to take some action with the ad. For example "Install".
@property(nonatomic, readonly, copy) NSString *callToAction;
/// Application icon.
@property(nonatomic, readonly, strong) HZGADNativeAdImage *icon;

#pragma mark - Recommended to display

/// App description.
@property(nonatomic, readonly, copy) NSString *body;
/// The app store name. For example, "App Store".
@property(nonatomic, readonly, copy) NSString *store;
/// String representation of the app's price.
@property(nonatomic, readonly, copy) NSString *price;
/// Array of GADNativeAdImage objects related to the advertised application.
@property(nonatomic, readonly, strong) NSArray *images;
/// App store rating (0 to 5).
@property(nonatomic, readonly, copy) NSDecimalNumber *starRating;

@end
