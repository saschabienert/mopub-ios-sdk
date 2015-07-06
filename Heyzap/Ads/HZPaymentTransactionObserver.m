/*
 * Copyright (c) 2015, Heyzap, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the name of 'Heyzap, Inc.' nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import "HZPaymentTransactionObserver.h"

#import "HZAPIClient.h"
#import "HZLog.h"
#import "HZDictionaryUtils.h"
#import "HeyzapMediation.h"

@interface HZPaymentTransactionObserver()<SKProductsRequestDelegate>

@end

@implementation HZPaymentTransactionObserver

+ (instancetype)sharedInstance
{
    static HZPaymentTransactionObserver *IAPObserver;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IAPObserver = [[HZPaymentTransactionObserver alloc] init];
    });
    
    return IAPObserver;
}

#pragma mark - SKPaymentTransactionObserver Protocol Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    NSMutableSet *productIds = [[NSMutableSet alloc] init];

    for (id transaction in transactions) {
        
        if ([transaction isKindOfClass:[SKPaymentTransaction class]]) {
            SKPaymentTransaction *paymentTransaction = (SKPaymentTransaction *)transaction;
            
            if (paymentTransaction.transactionState == SKPaymentTransactionStatePurchased) {
                [productIds addObject:paymentTransaction.payment.productIdentifier];
            }
        }
    }
    
    if ([productIds count]) {
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
        productsRequest.delegate = self;
        [productsRequest start];
    }
}

#pragma mark - SKProductsRequestDelegate Protocol Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *products = response.products;
    
    for (SKProduct *product in products) {
        [self onIAPPurchaseComplete:product.productIdentifier
                        productName:product.localizedTitle
                              price:product.price
                           currency:[product.priceLocale objectForKey:NSLocaleCurrencyCode]];
    }
}

#pragma mark - IAP Purchase recording

- (void)onIAPPurchaseComplete:(NSString *)productId productName:(NSString *)productName price:(NSDecimalNumber *)price {
    
    [self onIAPPurchaseComplete:productId
                    productName:productName
                          price:price
                       currency:[[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode]];
}

NSString * const kHZIAPMetricsEndPoint = @"in_game_api/metrics/iap";

- (void)onIAPPurchaseComplete:(NSString *)productId productName:(NSString *)productName price:(NSDecimalNumber *)price currency:(NSString *)currency {
    
    NSDictionary *params = @{
                             @"iab_id": productId,
                             @"name": productName,
                             @"price": price,
                             @"currency_code": currency ?: [NSNull null], // It's possible for NSLocale to not have a currency code. I don't think this should happen because presumably purchased items have a currency associated with them.
                             };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        [[HZAPIClient sharedClient] POST:kHZIAPMetricsEndPoint parameters:params success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
            
            if ([json[@"success"] integerValue]) {
                
                HeyzapMediation *mediation = [HeyzapMediation sharedInstance];
                mediation.adsTimeOut = mediation.IAPAdDisableTime;
                [HZLog debug: [NSString stringWithFormat: @"(IAP Transaction) %@", json]];
                
            } else {
                [HZLog error: [NSString stringWithFormat: @"(Unable to Send IAP Transaction Data) %@", operation]];
            }
            
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            
            [HZLog error: [NSString stringWithFormat: @"(Unable to Send IAP Transaction Data) %@", error]];
        }];

    });
}

@end
