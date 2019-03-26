//
//  PinView.h
//  BaiduMapDemo
//
//  Created by Gary Yao on 2019/3/25.
//  Copyright © 2019 mobilenow. All rights reserved.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZDCPinView : UIView
@property (nonatomic, strong) UIImage *image; //商户图
@property (nonatomic, copy) NSString *title; //商户名
@property (nonatomic, copy) NSString *subtitle; //地址
@end



NS_ASSUME_NONNULL_END
