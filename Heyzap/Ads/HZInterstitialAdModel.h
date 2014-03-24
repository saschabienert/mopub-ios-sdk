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

@property (nonatomic, readonly) NSString *HTMLContent;
@property (nonatomic, readonly) BOOL fillParentWidth;
@property (nonatomic, readonly) BOOL fillParentHeight;
@property (nonatomic, readonly) BOOL isFullScreen;
@property (nonatomic, readonly) CGSize dimensions;

@property (nonatomic, readonly) UIWebView *preloadWebview;

@end
