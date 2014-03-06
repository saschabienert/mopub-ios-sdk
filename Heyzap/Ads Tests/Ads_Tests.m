//
//  Ads_Tests.m
//  Ads Tests
//
//  Created by Maximilian Tagher on 3/6/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HZVideoAdModel.h"

@interface Ads_Tests : XCTestCase

@end

@implementation Ads_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTAssert(1 == 1, @"One should equal 1");
}

- (void)testCreativeTypes
{
    XCTAssert([HZVideoAdModel isValidForCreativeType:@"video"], @"Should be valid for video");
}

@end
