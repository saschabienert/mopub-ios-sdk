//
//  HZInMobiBannerAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdapter.h"

@interface HZInMobiBannerAdapter : HZBannerAdapter

- (instancetype)initWithAdPlacementID:(long long)placementID options:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter;

@end
