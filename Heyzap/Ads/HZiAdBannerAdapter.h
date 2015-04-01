//
//  HZiAdBannerAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdapter.h"

@interface HZiAdBannerAdapter : HZBannerAdapter

- (instancetype)initWithReportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter options:(HZBannerAdOptions *)options;

@end
