//
//  ADHomeViewCell.m
//
//  Created by 阿蛋 on 17/6/24.
//  Copyright © 2017年 adan. All rights reserved.
//

#import "ADHomeViewCell.h"
@interface ADHomeViewCell()

@end
@implementation ADHomeViewCell
- (void)awakeFromNib {
    [super awakeFromNib];
    self.iconView.userInteractionEnabled = YES;
}
-(void)setTitle:(NSString *)title
{
    self.classLB.text = title;
}
-(void)setName:(NSString *)name{
    self.nameLB.text = name;
}
@end
