//
//  ADTabbar.m
//
//  Created by mkxy on 17/3/2.
//  Copyright © 2017年 阿蛋. All rights reserved.
//

#import "ADTabbar.h"
#import "ADConst.h"

@interface ADTabbar()

@end
@implementation ADTabbar

-(void)layoutSubviews
{
    [super layoutSubviews];
    for (UIControl *tabbarBtn in self.subviews) {
        //1.遍历子控件,找出tabbarBtn
        if ([tabbarBtn isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            //添加点击事件
            [tabbarBtn addTarget:self action:@selector(tabbarBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}
//点击tabbarBtn,发出通知,做相应的事情
-(void)tabbarBtnClick:(UIControl *)tabbarBtn
{
    [[NSNotificationCenter defaultCenter]postNotificationName:ADTabbarChangeClick object:nil];
}
@end
