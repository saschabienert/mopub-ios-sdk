//
//  HZGADAdLoaderDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZGADAdLoader;
@class HZGADRequestError;

@protocol HZGADAdLoaderDelegate <NSObject>

- (void)adLoader:(HZGADAdLoader *)adLoader didFailToReceiveAdWithError:(HZGADRequestError *)error;

@end
