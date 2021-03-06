//
//  TestAppPaymentTransactionObserver.m
//  Heyzap
//
//  Created by Karim Piyarali on 6/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "TestAppPaymentTransactionObserver.h"

@implementation TestAppPaymentTransactionObserver

+ (instancetype)sharedInstance
{
    static TestAppPaymentTransactionObserver *testObserver;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        testObserver = [[TestAppPaymentTransactionObserver alloc] init];
    });
    
    return testObserver;
}

#pragma mark - SKPaymentTransactionObserver Protocol Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    
    for (id transaction in transactions) {
        
        if ([transaction isKindOfClass:[SKPaymentTransaction class]]) {
            SKPaymentTransaction *paymentTransaction = (SKPaymentTransaction *)transaction;
            
            if (paymentTransaction.transactionState == SKPaymentTransactionStatePurchased ||
                paymentTransaction.transactionState == SKPaymentTransactionStateFailed) {
                
                [queue finishTransaction:paymentTransaction];
                
                if (paymentTransaction.transactionState == SKPaymentTransactionStateFailed) {
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kHZPaymentTransactionErrorNotification
                                                                        object:paymentTransaction.error];
                }
            }
        }
    }
}

@end
