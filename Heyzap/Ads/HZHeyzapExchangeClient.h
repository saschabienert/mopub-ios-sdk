//
//  HZHeyzapExchangeClient.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/25/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZAdType.h"
#import "HZBannerAd.h"
#import "HZShowOptions.h"

@class HZHeyzapExchangeClient;
@protocol HZHeyzapExchangeClientDelegate <NSObject>

- (void) client:(HZHeyzapExchangeClient *)client didFetchAdWithType:(HZAdType)adType;
- (void) client:(HZHeyzapExchangeClient *)client didFailToFetchAdWithType:(HZAdType)adType error:(NSString *)error;
- (void) client:(HZHeyzapExchangeClient *)client didHaveError:(NSString *)error;
- (void) didStartAdWithClient:(HZHeyzapExchangeClient *)client;
- (void) didEndAdWithClient:(HZHeyzapExchangeClient *)client successfullyFinished:(BOOL)successfullyFinished;
- (void) adClickedWithClient:(HZHeyzapExchangeClient *)client;

@end

typedef NS_ENUM(NSUInteger, HZHeyzapExchangeClientState){
    HZHeyzapExchangeClientStateNone,
    HZHeyzapExchangeClientStateFetching,
    HZHeyzapExchangeClientStateReady,
    HZHeyzapExchangeClientStateFailure,
    HZHeyzapExchangeClientStateFinished
};

@interface HZHeyzapExchangeClient : NSObject

@property (nonatomic, weak) id<HZHeyzapExchangeClientDelegate> delegate;
@property (nonatomic) BOOL isWithAudio;
@property (nonatomic, readonly) HZAdType adType;
@property (nonatomic, readonly) NSNumber *adScore;
@property (nonatomic, readonly) HZHeyzapExchangeClientState state;

- (void) fetchForAdType:(HZAdType)adType;
- (void) showWithOptions:(HZShowOptions *)options;

+ (NSString *)supportedFormatsString;
@end