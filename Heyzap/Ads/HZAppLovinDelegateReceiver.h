//
//  HZAppLovinDelegateReceiver.h
//  Heyzap
//
//  Created by Mike Urbach on 3/31/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZAdType.h"

// AppLovin uses the same delegate selectors for incentivized/interstitial, so we need separate objects to break down the messages by ad types.
@protocol HZAppLovinDelegateReceiver <NSObject>

- (void)didLoadAdOfType:(HZAdType)type;
- (void)didFailToLoadAdOfType:(HZAdType)type error:(NSError *)error;

- (void)didClickAd;
- (void)didDismissAd;

- (void)willPlayAudio;
- (void)didFinishAudio;

- (void)didCompleteIncentivized;
- (void)didFailToCompleteIncentivized;


@end
