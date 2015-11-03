//
//  NativeTableViewCell.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "NativeTableViewCell.h"
#import "HZNativeAd.h"
#import "UIImageView+AFNetworking.h"
#import "HZNativeAdImage.h"

@interface NativeTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@end

@implementation NativeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.iconImageView.layer.cornerRadius = 15;
    self.iconImageView.layer.masksToBounds = YES;
}

- (void)configureWithAd:(HZNativeAd *)nativeAd {
    self.appNameLabel.text = nativeAd.appName;
    [self.iconImageView setImageWithURL:nativeAd.iconImage.url];
}

@end
