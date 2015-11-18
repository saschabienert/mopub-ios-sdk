//
//  HZMediationTestSuite.h
//  Heyzap
//
//  Created by Monroe Ekilah on 10/12/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZSDCSegmentedViewController.h"

@protocol HZMediationTestSuiteManager;
@protocol HZMediationTestSuitePage <NSObject>
- (void) infoButtonPressed;
- (void) setDelegate:(id<HZMediationTestSuiteManager>)delegate;
@optional
- (void) hide;
@end

@protocol HZMediationTestSuiteManager <NSObject>
- (void) didLoad:(UIViewController <HZMediationTestSuitePage> *)vc;

@end

@interface HZMediationTestSuite : NSObject <HZMediationTestSuiteManager>

- (void) showWithCompletion:(void (^)())completion;
- (void) hide;
@end