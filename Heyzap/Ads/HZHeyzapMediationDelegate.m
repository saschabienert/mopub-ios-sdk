//
//  HZHeyzapMediationDelegate.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/18/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapMediationDelegate.h"
#import "HZMediationConstants.h"

@interface HZHeyzapMediationDelegate()

@property (nonatomic) HZAdType adType;
@property (nonatomic, weak) id<HZHeyzapDelegateReceiver> delegate;

@end

@implementation HZHeyzapMediationDelegate

- (id)initWithAdType:(HZAdType)adType delegate:(id<HZHeyzapDelegateReceiver>)delegate
{
    NSParameterAssert(delegate);
    self = [super init];
    if (self) {
        _adType = adType;
        _delegate = delegate;
    }
    return self;
}

- (void)didFailToShowAdWithTag:(NSString *)tag andError:(NSError *)error
{
    [self.delegate didDismissAd];
}

- (void)didFailToReceiveAdWithTag: (NSString *) tag
{
    [self.delegate didFailToLoadAdOfType:self.adType
                                   error:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil]];
}

- (void)didClickAdWithTag: (NSString *) tag
{
    [self.delegate didClickAd];
}

- (void)didHideAdWithTag: (NSString *) tag
{
    [self.delegate didDismissAd];
}

#pragma mark - Incentivized

- (void)didCompleteAd
{
    [self.delegate didCompleteIncentivizedAd];
}

- (void)didFailToCompleteAd
{
    [self.delegate didFailToCompleteIncentivizedAd];
}

#pragma mark - Audio

- (void)willStartAudio
{
    
}

- (void) didFinishAudio
{
    
}
@end
