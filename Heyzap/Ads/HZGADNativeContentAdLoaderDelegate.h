//
//  HZGADNativeContentAdLoaderDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZGADAdLoaderDelegate.h"

@class HZGADAdLoader;
@class HZGADNativeContentAd;

@protocol HZGADNativeContentAdLoaderDelegate <HZGADAdLoaderDelegate>

- (void)adLoader:(HZGADAdLoader *)adLoader
didReceiveNativeContentAd:(HZGADNativeContentAd *)nativeContentAd;;

@end
