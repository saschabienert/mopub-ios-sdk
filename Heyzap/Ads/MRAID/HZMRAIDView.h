//
//  SKMRAIDView.h
//  MRAID
//
//  Created by Jay Tucker on 9/13/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HZMRAIDView;
@protocol HZMRAIDServiceDelegate;

// A delegate for MRAIDView to listen for notification on ad ready or expand related events.
@protocol HZMRAIDViewDelegate <NSObject>

@optional

// These callbacks are for basic banner ad functionality.
- (void)mraidViewAdReady:(HZMRAIDView *)mraidView;
- (void)mraidViewAdFailed:(HZMRAIDView *)mraidView;
- (void)mraidViewWillExpand:(HZMRAIDView *)mraidView;
- (void)mraidViewDidClose:(HZMRAIDView *)mraidView;
- (void)mraidViewNavigate:(HZMRAIDView *)mraidView withURL:(NSURL *)url;

// This callback is to ask permission to resize an ad.
- (BOOL)mraidViewShouldResize:(HZMRAIDView *)mraidView toPosition:(CGRect)position allowOffscreen:(BOOL)allowOffscreen;

@end

@interface HZMRAIDView : UIView

@property (nonatomic, weak) id<HZMRAIDViewDelegate> delegate;
@property (nonatomic, weak) id<HZMRAIDServiceDelegate> serviceDelegate;
@property (nonatomic, weak, setter = setRootViewController:, getter=rootViewController) UIViewController *rootViewController;
@property (nonatomic, assign, getter = isViewable, setter = setIsViewable:) BOOL isViewable;

// IMPORTANT: This is the only valid initializer for an MRAIDView; -init and -initWithFrame: will throw exceptions
- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
  supportedFeatures:(NSArray *)features
           delegate:(id<HZMRAIDViewDelegate>)delegate
   serviceDelegate:(id<HZMRAIDServiceDelegate>)serviceDelegate
 rootViewController:(UIViewController *)rootViewController;

- (void)cancel;

@end
