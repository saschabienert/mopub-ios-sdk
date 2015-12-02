//
//  HZGADNativeAdImage.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@interface HZGADNativeAdImage : HZClassProxy

/// The image's URL.
@property(nonatomic, readonly, strong) NSURL *imageURL;

/// The image's scale.
@property(nonatomic, readonly, assign) CGFloat scale;

@end
