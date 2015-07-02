//
//  HZHeyzapExchangeFormat.h
//  Heyzap
//
//  Created by Monroe Ekilah on 7/1/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

// The values of this enum match the values the server expects.
typedef NS_ENUM(NSUInteger, HZHeyzapExchangeFormat) {
    HZHeyzapExchangeFormatUnknown          = 0, //0
    HZHeyzapExchangeFormatVPAID_1          = 1, //1
    HZHeyzapExchangeFormatVPAID_2          = 2, //2
    HZHeyzapExchangeFormatMRAID_1          = 3, //3
    HZHeyzapExchangeFormatORMMA            = 4, //4
    HZHeyzapExchangeFormatMRAID_2          = 5, //5
    HZHeyzapExchangeFormatVAST_1_0         = 6, //6
    HZHeyzapExchangeFormatVAST_2_0         = 7, //7
    HZHeyzapExchangeFormatVAST_3_0         = 8, //8
    HZHeyzapExchangeFormatVAST_1_0_WRAPPER = 9, //9
    HZHeyzapExchangeFormatVAST_2_0_WRAPPER = 10,//10
    HZHeyzapExchangeFormatVAST_3_0_WRAPPER = 11,//11
};
