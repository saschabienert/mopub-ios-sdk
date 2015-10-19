//
//  HZKIFTestCase.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/15/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <KIF/KIF.h>
#import "OHHTTPStubs+Heyzap.h"
#import "HeyzapAds.h"
#import "HZUtils.h"
#import "TestJSON.h"

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

@interface HZKIFTestCase : KIFTestCase

extern NSString * const kCloseButtonAccessibilityLabel;

@end
