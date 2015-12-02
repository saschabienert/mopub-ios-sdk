//
//  HZGADNativeContentAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZGADNativeAdImage;

@interface HZGADNativeContentAd : HZClassProxy

#pragma mark - Must be displayed

/// Primary text headline.
@property(nonatomic, readonly, copy) NSString *headline;
/// Secondary text.
@property(nonatomic, readonly, copy) NSString *body;

#pragma mark - Recommended to display

/// Large images.
@property(nonatomic, readonly, copy) NSArray *images;
/// Small logo image.
@property(nonatomic, readonly, strong) HZGADNativeAdImage *logo;
/// Text that encourages user to take some action with the ad.
@property(nonatomic, readonly, copy) NSString *callToAction;
/// Identifies the advertiser. For example, the advertiser’s name or visible URL.
@property(nonatomic, readonly, copy) NSString *advertiser;

@end
