//
//  HZHeyzapExchangeBannerClient.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/29/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//
#import <Foundation/Foundation.h>

@class HZHeyzapExchangeBannerClient;
@protocol HZHeyzapExchangeBannerClientDelegate <NSObject>

- (void) fetchFailedWithClient:(HZHeyzapExchangeBannerClient *)client;

@end

@interface HZHeyzapExchangeBannerClient : NSObject
@property (nonatomic, weak) id<HZHeyzapExchangeBannerClientDelegate>delegate;
@end