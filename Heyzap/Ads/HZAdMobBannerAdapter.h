//
//  HZAdMobBannerAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/17/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdapter.h"
@class HZGADBannerView;
@class HZGADRequest;

@interface HZAdMobBannerAdapter : HZBannerAdapter

- (instancetype)initWithAdUnitID:(NSString *)adUnitID options:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter request:(HZGADRequest *)request;

@end
