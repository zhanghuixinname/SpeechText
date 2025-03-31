//
//  UIColor+Hex.h
//  HealthAssistantStandard
//
//  Created by ebao on 2017/7/12.
//  Copyright © 2017年 ebao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hex)

//从十六进制字符串获取颜色，
//color:支持@“#123456”、 @“0X123456”、 @“123456”三种格式
+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha;

@end
