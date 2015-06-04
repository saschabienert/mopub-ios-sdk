//
//  TestAppPaymentTransactionObserver.h
//  Heyzap
//
//  Created by Karim Piyarali on 6/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface TestAppPaymentTransactionObserver : NSObject<SKPaymentTransactionObserver>

+ (instancetype) sharedInstance;

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;

@end
