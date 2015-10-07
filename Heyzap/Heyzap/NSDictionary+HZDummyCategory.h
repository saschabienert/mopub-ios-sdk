//
//  HZDummyCategory.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/7/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *  Code in categories from static libraries isn't loaded without adding -ObjC to "Other Linker Flags".
 *  We also need -ObjC to have the 3rd party SDKs included without referencing them statically.
 *  This category let's us test that.
 */
@interface NSDictionary (HZDummyCategory)

- (void)hzDummyMethod;

@end
