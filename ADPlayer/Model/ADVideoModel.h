//
//  ADVideoModel.h
//  ADPlayer
//
//  Created by 阿蛋 on 17/8/6.
//  Copyright © 2017年 adan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADVideoModel : NSObject
//标题
@property (nonatomic,copy) NSString *title;
//占位图
@property (nonatomic,copy) NSString *cover;
//视频地址
@property (nonatomic,copy) NSString *mp4_url;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end
