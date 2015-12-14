//
//  AbstractHeyzapTest.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/10/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZKIFTestCase.h"

@interface AbstractHeyzapTest : HZKIFTestCase

- (void)stubStartAndMediate;
- (void)stubWebViewContent;
- (void)stubHeyzapEventEndpoints;

- (void)closeHeyzapWebView;
- (UIWebView *)findWebview;

@end
