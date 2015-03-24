//
//  HZHZAdMobBannerSupport.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"
#import "HZGADBannerView.h"


@interface HZHZAdMobBannerSupport : HZClassProxy

+ (HZGADAdSize)adSizeNamed:(NSString *)name;

@end
