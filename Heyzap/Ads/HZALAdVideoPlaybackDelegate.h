//
//  HZALAdVideoPlaybackDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/18/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZALAd;

@protocol HZALAdVideoPlaybackDelegate <NSObject>

- (void)videoPlaybackBeganInAd:(HZALAd *)ad;

- (void)videoPlaybackEndedInAd:(HZALAd *)ad atPlaybackPercent:(NSNumber *)percentPlayed fullyWatched:(BOOL)wasFullyWatched;

@end
