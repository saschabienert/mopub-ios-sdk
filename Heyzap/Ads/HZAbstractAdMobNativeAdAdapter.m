//
//  HZAbstractAdMobNativeAdAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 11/17/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZAbstractAdMobNativeAdAdapter.h"
#import "HZView.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface HZAbstractAdMobNativeAdAdapter()

@property (nonatomic) NSTimer *impressionCheckingTimer;

@end

@implementation HZAbstractAdMobNativeAdAdapter

// Each AdMob native ad has its own UIView subclass (e.g. GADNativeContentAdView).
// We need to know when that view is on-screen. To do this, I subclass the AdMob class and override `didMoveToWindow`
// When the view is added to the window, our subclass sends `admobWrapperMovedToWindow` to its delegate, the adapter (see method below)
// At this point the adapter uses a timer to continually check if the AdMob ad is actually visible on screen. If so, an impression is reported.
+ (Class)wrapperViewSubclass:(NSString *)subclassName forSuperclass:(NSString *)superclassName {
    Class wrapperSuperClass = NSClassFromString(superclassName);
    Class subclass = objc_allocateClassPair(wrapperSuperClass, [subclassName UTF8String], 0);
    
    // class_addIvar line from: https://www.mikeash.com/pyblog/friday-qa-2010-11-6-creating-classes-at-runtime-in-objective-c.html
    class_addIvar(subclass, "_heyzapDelegate", sizeof(id), rint(log2(sizeof(id))), @encode(id));
    
    IMP imp = imp_implementationWithBlock(^(id theSelf){
        // AdMob requires calling super for all overridden methods
        struct objc_super super_data = { theSelf, wrapperSuperClass };
        objc_msgSendSuper(&super_data, @selector(didMoveToWindow));
        
        Ivar ivar = class_getInstanceVariable([theSelf class], "_heyzapDelegate");
        id delegate = object_getIvar(theSelf, ivar);
        
        [delegate performSelector:@selector(admobWrapperMovedToWindow)];
    });
    
    class_addMethod(subclass, @selector(didMoveToWindow), imp, "v@");
    
    objc_registerClassPair(subclass);
    return subclass;
}

- (void)admobWrapperMovedToWindow {
    UIView *view = (UIView *)self.wrapperView;
    if (!view.window) {
        [self.impressionCheckingTimer invalidate];
        self.impressionCheckingTimer = nil;
    } else if (!self.hasReportedImpression) {
        self.impressionCheckingTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                        target:self
                                                                      selector:@selector(checkVisibility:)
                                                                      userInfo:nil
                                                                       repeats:YES];
    }
}

- (void)checkVisibility:(NSTimer *)timer {
    if ([HZView isViewVisible:(UIView *)self.wrapperView]) {
        [self reportImpressionIfNecessary];
        [self.impressionCheckingTimer invalidate];
        self.impressionCheckingTimer = nil;
    }
}

@end
