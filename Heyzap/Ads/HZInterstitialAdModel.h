//
//  HZInterstitialAdModel.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HZAdModel.h"

@interface HZInterstitialAdModel : HZAdModel

@property (nonatomic) NSString *HTMLContent;
@property (nonatomic, assign) BOOL fillParentWidth;
@property (nonatomic, assign) BOOL fillParentHeight;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic) CGSize dimensions;

@property (nonatomic) UIWebView *preloadWebview;

@end
