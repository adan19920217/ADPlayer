//
//  ADHomeViewCell.h
//
//  Created by 阿蛋 on 17/6/24.
//  Copyright © 2017年 adan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ADHomeViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLB;
@property (weak, nonatomic) IBOutlet UILabel *classLB;
@property(nonatomic,copy)NSString *title;
@property(nonatomic,copy)NSString *name;
@end
