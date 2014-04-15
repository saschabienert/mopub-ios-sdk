//
//  HZAppLovinAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZBaseAdapter.h"

// AppLovin uses the same delegate selectors for incentivized/interstitial, so we need separate objects to break down the messages by ad types.
@protocol HZAppLovinDelegateReceiver <NSObject>

- (void)didLoadAdOfType:(HZAdType)type;
- (void)didFailToLoadAdOfType:(HZAdType)type error:(NSError *)error;

- (void)didClickAd;
- (void)didDismissAd;


@end

@interface HZAppLovinAdapter : HZBaseAdapter <HZAppLovinDelegateReceiver>

@end
