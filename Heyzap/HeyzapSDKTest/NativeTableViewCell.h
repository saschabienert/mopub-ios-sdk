//
//  NativeTableViewCell.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HZNativeAdModel;

@interface NativeTableViewCell : UITableViewCell

- (void)configureWithAd:(HZNativeAdModel *)nativeAd;

@end
