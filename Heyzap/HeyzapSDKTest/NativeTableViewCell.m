//
//  NativeTableViewCell.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "NativeTableViewCell.h"
#import "HZImageView.h"
#import "HZNativeAdModel.h"

@interface NativeTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet HZImageView *iconImageView;

@end

@implementation NativeTableViewCell

- (void)configureWithAd:(HZNativeAdModel *)nativeAd {
    self.appNameLabel.text = nativeAd.appName;
    [self.iconImageView HZsetImageWithURL:nativeAd.iconURL];
}

@end
