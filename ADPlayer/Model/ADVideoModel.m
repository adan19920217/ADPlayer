//
//  ADVideoModel.m
//  ADPlayer
//
//  Created by 阿蛋 on 17/8/6.
//  Copyright © 2017年 adan. All rights reserved.
//

#import "ADVideoModel.h"

@implementation ADVideoModel
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}
- (instancetype)initWithDictionary:(NSDictionary *)dict

{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

@end
