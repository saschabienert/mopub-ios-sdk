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

+ (Class)wrapperViewSubclass:(NSString *)subclassName forSuperclass:(NSString *)superclassName {
    Class wrapperSuperClass = NSClassFromString(superclassName);
    Class subclass = objc_allocateClassPair(wrapperSuperClass, [subclassName UTF8String], 0);
    
    class_addIvar(subclass, "_heyzapDelegate", sizeof(id), rint(log2(sizeof(id))), @encode(id));
    
    IMP imp = imp_implementationWithBlock(^(id theSelf){
        class_getSuperclass(subclass);
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
