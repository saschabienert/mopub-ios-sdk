//
//  ViewController.m
//  TestUIWebView
//
//  Created by Maximilian Tagher on 4/30/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIWebViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;
    NSLog(@"Enabled = %i",self.webView.userInteractionEnabled);
    NSError *error;
    NSString *html = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://s3.amazonaws.com/uploads.hipchat.com/1658/24694/aj9sjsg2igs9drs/test.html"] encoding:NSUTF8StringEncoding error:&error];
    [self.webView loadHTMLString:html baseURL:nil];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"Should load request = %@",request);
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
