//
//  HZBannerAdaper.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBannerAdWrapper_Private.h"

@interface HZBannerAdapter : NSObject

@property (nonatomic, weak) id<HZBannerAdWrapperReporter> reportingDelegate;

@property (nonatomic, strong, readonly) NSString *networkName;

- (UIView *)mediatedBanner;

@end
