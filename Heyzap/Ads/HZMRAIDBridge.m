//
//  HZMRAIDBridge.m
//  Heyzap
//
//  Created by Daniel Rhodes on 6/10/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMRAIDBridge.h"
#import <UIKit/UIKit.h>

@interface HZMRAIDBridge()
@property (nonatomic, strong) UIWebView *webview;
@end

@implementation HZMRAIDBridge

- (id) initWithWebView: (UIWebView *) webview {
    if (self = [super init]) {
        
    }
    
    return self;
}

- (void) injectJavaScript: (NSString *) JS {
    [self.webview stringByEvaluatingJavaScriptFromString: JS];
}
@end
