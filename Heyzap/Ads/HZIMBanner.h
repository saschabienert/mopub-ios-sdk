//
//  HZIMBanner.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@protocol HZIMBannerDelegate;

@interface HZIMBanner : HZClassProxy

/**
 * The delegate for the banner to notify of events.
 */
@property (nonatomic, weak) id<HZIMBannerDelegate> delegate;
/**
 * The refresh interval for the banner specified in seconds.
 */
@property (nonatomic) NSInteger refreshInterval;
/**
 * A free form set of keywords, separated by ',' to be sent with the ad request.
 * E.g: "sports,cars,bikes"
 */
@property (nonatomic, strong) NSString* keywords;
/**
 * Any additional information to be passed to InMobi.
 */
@property (nonatomic, strong) NSDictionary* extras;
/**
 * The placement ID for this banner.
 */
@property (nonatomic) long long placementId;
/**
 * The transition animation to be performed between refreshes.
 */
@property (nonatomic) UIViewAnimationTransition transitionAnimation;
/**
 * Initializes an IMBanner instance with the specified placementId.
 * @param frame CGRect for this view, according to the requested size.
 * @param placementId  the placement Id registered on the InMobi portal.
 */
-(instancetype)initWithFrame:(CGRect)frame placementId:(long long)placementId;
/**
 * Initializes an IMBanner instance with the specified placementId and delegate.
 * @param frame CGRect for this view, according to the requested size.
 * @param placementId  the placement Id registered on the InMobi portal.
 * @param delegate The delegate to receive callbacks
 */
-(instancetype)initWithFrame:(CGRect)frame placementId:(long long)placementId delegate:(id<HZIMBannerDelegate>)delegate;
/**
 * Loads a banner with default values.
 */
-(void)load;
/**
 * Specifies if the banner should auto refresh
 * @param refresh if the banner should be refreshed
 */
-(void)shouldAutoRefresh:(BOOL)refresh;
-(void)setRefreshInterval:(NSInteger)interval;

@end
