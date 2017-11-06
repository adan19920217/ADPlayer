//
//  ADTopicCell.m
//
//  Created by mkxy on 17/4/11.
//  Copyright © 2017年 阿蛋. All rights reserved.
//

#import "ADTopicCell.h"
#import "UIImage+ADImage.h"
@interface ADTopicCell()

@property (weak, nonatomic) IBOutlet UILabel *nameLB;
@property (weak, nonatomic) IBOutlet UILabel *passTimeLB;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@end
@implementation ADTopicCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"mainCellBackground"]];
    self.iconImageView.userInteractionEnabled = YES;
    UIImage * image = [[UIImage imageNamed:@"cat"]circleImage];
    self.iconView.image = image;
}

@end
