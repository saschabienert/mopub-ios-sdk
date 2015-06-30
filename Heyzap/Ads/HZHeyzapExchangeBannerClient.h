//
//  HZHeyzapExchangeBannerClient.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/29/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "HZMRAIDView.h"
#import "HZBannerAdOptions.h"

@class HZHeyzapExchangeBannerClient;
@protocol HZHeyzapExchangeBannerClientDelegate <NSObject>

- (void) fetchFailedWithClient:(HZHeyzapExchangeBannerClient *)client;
- (void) fetchSuccessWithClient:(HZHeyzapExchangeBannerClient *)client banner:(HZMRAIDView *)banner;
@end

@interface HZHeyzapExchangeBannerClient : NSObject

@property (nonatomic, weak) id<HZHeyzapExchangeBannerClientDelegate>delegate;

- (void) fetchWithOptions:(HZBannerAdOptions *)options delegate:(id<HZMRAIDViewDelegate>)delegate;
@end