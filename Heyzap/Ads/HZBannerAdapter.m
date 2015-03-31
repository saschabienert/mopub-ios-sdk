//
//  HZBannerAdaper.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdapter.h"

#define ABSTRACT_METHOD_ERROR() @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Subclasses should override this method" userInfo:nil];

@interface HZBannerAdapter()

@property (nonatomic, weak) NSTimer *impressionCheckerTimer;

@end

@implementation HZBannerAdapter

- (UIView *)mediatedBanner {
    ABSTRACT_METHOD_ERROR();
}

- (NSString *)networkName {
    ABSTRACT_METHOD_ERROR();
}

- (BOOL)isAvailable {
    ABSTRACT_METHOD_ERROR();
}



- (void)startMonitoringForImpression {
    if (!self.impressionCheckerTimer) {
        self.impressionCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
        self.impressionCheckerTimer.tolerance = 0.5;
    }
}

- (void)timerFired:(NSTimer *)timer {
    if ([self mediatedBanner].superview) {
        [self.bannerReportingDelegate bannerAdapter:self wasClickedForSession:self.session];
        [timer invalidate];
        self.impressionCheckerTimer = nil;
    }
}

- (void)stopTryingToLoadBanner {
    [self.impressionCheckerTimer invalidate];
    self.impressionCheckerTimer = nil;
}

@end
