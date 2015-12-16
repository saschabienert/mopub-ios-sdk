//
//  MediatedNativeTableViewCell.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "MediatedNativeTableViewCell.h"
#import "HZMediatedNativeAd.h"
#import "HZMediatedNativeAdViewRegisterer.h"
#import "UIImageView+AFNetworking.h"
#import "HZNativeAdImage.h"

@interface MediatedNativeTableViewCell ()

@property (nonatomic, weak) HZMediatedNativeAd *nativeAd;

@property (nonatomic, weak) UIView *wrapperView;

@property (nonatomic) UILabel *adTypeLabel;
@property (nonatomic) UILabel *reportedImpressionLabel;
@property (nonatomic) UILabel *reportedClickLabel;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UITextView *bodyTextView;

@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) UIImageView *iconView;

@property (nonatomic) UIView *gradientView;
@property (nonatomic) UILabel *ctaLabel;

@end

@implementation MediatedNativeTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        const CGFloat inset = 15;
        
        UIFont *const metadataFont = [UIFont systemFontOfSize:10];
        
        self.adTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, 0, 200, 20)];
        self.adTypeLabel.font = metadataFont;
        self.reportedImpressionLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(self.adTypeLabel.frame), 200, 20)];
        self.reportedImpressionLabel.font = metadataFont;
        self.reportedClickLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(self.reportedImpressionLabel.frame), 200, 20)];
        self.reportedClickLabel.font = metadataFont;
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(self.reportedClickLabel.frame), 320, 30)];
        
        self.bodyTextView = [[UITextView alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(self.titleLabel.frame), 280, 50) textContainer:nil];
        self.bodyTextView.userInteractionEnabled = NO;
        self.bodyTextView.editable = NO;
        self.bodyTextView.scrollEnabled = NO;
        
        self.gradientView = [[UIView alloc] initWithFrame:CGRectMake(inset, 0, 100, 50)];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.ctaLabel.bounds;
        
        
        
        UIColor *topGradient = [UIColor colorWithRed:92/255.0f green:176/255.0f blue:40/255.0f alpha:1];
        UIColor *bottomGradient = [UIColor colorWithRed:60/255.0f green:156/255.0f blue:5/255.0f alpha:1];
        gradient.colors = @[(id)topGradient.CGColor, (id)bottomGradient.CGColor];
        [self.gradientView.layer insertSublayer:gradient atIndex:0];
        
        self.ctaLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.gradientView.bounds.size.width, self.gradientView.bounds.size.height)];
        self.ctaLabel.backgroundColor = [UIColor colorWithRed:64/255.0f green:159/255.0f blue:12/255.0f alpha:1];
        self.ctaLabel.font = [UIFont boldSystemFontOfSize:16];
        self.ctaLabel.textColor = [UIColor whiteColor];
        self.ctaLabel.textAlignment = NSTextAlignmentCenter;
        [self.gradientView addSubview:self.ctaLabel];
        
        
        self.iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)configureWithNativeAd:(HZMediatedNativeAd *)nativeAd {
    self.nativeAd = nativeAd;
    
    [self configureEventReportingLabels];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configureEventReportingLabels)
                                                 name:HZMediatedNativeAdImpressionNotification
                                               object:self.nativeAd];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configureEventReportingLabels)
                                                 name:HZMediatedNativeAdClickNotification
                                               object:self.nativeAd];
    
    self.wrapperView = self.nativeAd.wrapperView;
    
    self.wrapperView.frame = self.contentView.bounds;
    
    [self.contentView addSubview:self.wrapperView];
    
    self.titleLabel.text = self.nativeAd.title;
    self.adTypeLabel.text = [@"Ad Type: " stringByAppendingString:NSStringFromHZMediatedNativeAdType(self.nativeAd.adType)];
    self.bodyTextView.text = self.nativeAd.body;
    self.ctaLabel.text = self.nativeAd.callToAction;
    
    HZNativeAdImage *adImage = self.nativeAd.iconImage;
    
    const CGFloat imageSide = 70;
    
    self.iconView.frame = CGRectMake(CGRectGetMaxX(self.wrapperView.bounds) - imageSide - 10, 30, imageSide, imageSide);
    [self.iconView setImageWithURL:adImage.url];
    
    self.coverImageView.frame = CGRectMake(0, CGRectGetMaxY(self.bodyTextView.frame), self.contentView.bounds.size.width, 100);
    
    
    [self.coverImageView setImageWithURL:[self.nativeAd coverImageWithPreferredOrientation:HZPreferredImageOrientationLandscape].url];
    
    CGRect gradientTmpFrame = self.gradientView.frame;
    gradientTmpFrame.origin.y = CGRectGetMaxY(self.coverImageView.frame) + 5;
    self.gradientView.frame = gradientTmpFrame;
    
    
    // Metadata Properties
    [self.wrapperView addSubview:self.adTypeLabel];
    [self.wrapperView addSubview:self.reportedImpressionLabel];
    [self.wrapperView addSubview:self.reportedClickLabel];
    
    // Native Ad Properties
    [self.wrapperView addSubview:self.titleLabel];
    [self.wrapperView addSubview:self.bodyTextView];
    [self.wrapperView addSubview:self.coverImageView];
    [self.wrapperView addSubview:self.gradientView];
    [self.wrapperView addSubview:self.iconView];
    
    [self.nativeAd registerViews:^(id<HZMediatedNativeAdViewRegisterer>registerer) {
        [registerer registerTitleView:self.titleLabel tappable:YES];
        [registerer registerBodyView:self.bodyTextView tappable:YES];
        [registerer registerCallToActionView:self.gradientView];
        [registerer registerIconView:self.iconView tappable:YES];
        [registerer registerCoverImageView:self.coverImageView tappable:YES];
    }];
}

- (void)configureEventReportingLabels {
    self.reportedImpressionLabel.text = [NSString stringWithFormat:@"Reported Impression: %@",(self.nativeAd.hasHadImpression ? @"☑︎" : @"☒")];
    self.reportedClickLabel.text = [NSString stringWithFormat:@"Reported Click: %@",(self.nativeAd.hasBeenClicked ? @"☑︎" : @"☒")];
}

- (void)prepareForReuse {
    for (UIView *subview in self.wrapperView.subviews) {
        [subview removeFromSuperview];
    }
    [self.wrapperView removeFromSuperview];
    self.wrapperView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:HZMediatedNativeAdImpressionNotification
                                                  object:self.nativeAd];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:HZMediatedNativeAdClickNotification
                                                  object:self.nativeAd];
    
    self.nativeAd = nil;
    
    [super prepareForReuse];
}

@end
