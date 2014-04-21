//
//  HZHeyzapProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"

@protocol HZHeyzapDelegateReceiver <NSObject>

- (void)didLoadAdOfAdType:(HZAdType)type;
- (void)didFailToLoadAdOfType:(HZAdType)type error:(NSError *)error;

- (void)didClickAd;
- (void)didDismissAd;

- (void)didCompleteIncentivizedAd;
- (void)didFailToCompleteIncentivizedAd;

- (void)willPlayAudio;
- (void)didFinishPlayingAudio;


@end

@interface HZHeyzapAdapter : HZBaseAdapter

@end
