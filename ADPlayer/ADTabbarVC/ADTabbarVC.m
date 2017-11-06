//
//  ADTabbarVC.m
//  ADPlayer
//
//  Created by 阿蛋 on 17/11/6.
//  Copyright © 2017年 adan. All rights reserved.
//

#import "ADTabbarVC.h"
#import "ADTabbar.h"
@interface ADTabbarVC ()

@end

@implementation ADTabbarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //替换系统tabbar
    [self setupTabBar];
}
+(void)load
{
    UITabBarItem *item = [UITabBarItem appearanceWhenContainedIn:self, nil];
    NSMutableDictionary *arr = [NSMutableDictionary dictionary];
    arr[NSForegroundColorAttributeName] = [UIColor orangeColor];
    [item setTitleTextAttributes:arr forState:UIControlStateSelected];
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    dic[NSFontAttributeName] = [UIFont systemFontOfSize:11];
    [item setTitleTextAttributes:dic forState:UIControlStateNormal];
}
-(void)setupTabBar
{
    ADTabbar *tabbar = [[ADTabbar alloc]init];
    [self setValue:tabbar forKeyPath:@"tabBar"];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
