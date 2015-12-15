//
//  HZKIFTestCase.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/15/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZKIFTestCase.h"
#import "IntegrationTestConfig.h"
#import "OHHTTPStubs+Heyzap.h"
#import "HeyzapMediation.h"
#import "HZMediationPersistentConfig.h"

@implementation HZKIFTestCase

+ (void)setUp {
    [super setUp];
    [OHHTTPStubs onStubActivation:^(NSURLRequest * _Nonnull request, id<OHHTTPStubsDescriptor>  _Nonnull stub) {
        NSLog(@"Activated stub for URL: %@",request.URL);
    }];
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:[TestJSON jsonForResource:@"start"]];
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:[TestJSON jsonForResource:@"mediate"]];
    
    [HZLog setDebugLevel:HZDebugLevelVerbose];
    [HeyzapAds startWithPublisherID:@"1234" andOptions:HZAdOptionsDisableAutoPrefetching];
    
    // TODO: Use a separate bundle ID for the IntegrationTestHost so that files on disk aren't shared between the test app and the integration tests.
    // We'll probably want this to be a separate app on third party networks' dashboards, anyway, so that we can enable test mode for those apps.
    [[HeyzapMediation sharedInstance].persistentConfig removeDisabledNetworks:[HeyzapMediation sharedInstance].persistentConfig.allDisabledNetworks];
}

- (void)beforeEach {
    [super beforeEach];
    
    NSLog(@"HTTP stubbing is: %i",[IntegrationTestConfig sharedConfig].shouldStubHTTPRequests);
    [OHHTTPStubs setEnabled:[IntegrationTestConfig sharedConfig].shouldStubHTTPRequests];
}

- (void)afterEach {
    [super afterEach];
    
    [OHHTTPStubs removeAllStubs];
    
    [HZInterstitialAd setCreativeID:0];
    [HZVideoAd setCreativeID:0];
    [HZIncentivizedAd setCreativeID:0];
}

#pragma mark - Stubs

- (void)stubStartAndMediate {
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:[TestJSON jsonForResource:@"start"]];
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:[TestJSON jsonForResource:@"mediate"]];
}

#pragma mark - Searching the view (controller) hierarchy

- (id)findViewOfClass:(Class)class {
    return [self findViewOfClass:class inView:[UIApplication sharedApplication].keyWindow];
}

- (id)findViewOfClass:(Class)class inView:(UIView *)view {
    if ([view isKindOfClass:class]) {
        return view;
    } else {
        for (UIView *subview in view.subviews) {
            id maybeView = [self findViewOfClass:class inView:subview];
            if (maybeView) {
                return maybeView;
            }
        }
        return nil;
    }
}

@end
