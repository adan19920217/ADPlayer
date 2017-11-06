//
//  UIImage+ADImage.m
//
//  Created by mkxy on 17/3/2.
//  Copyright © 2017年 阿蛋. All rights reserved.
//

#import "UIImage+ADImage.h"

@implementation UIImage (ADImage)
+(UIImage *)imageOriginalWithName:(NSString *)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}
//将一张图片剪成圆形图片
-(instancetype)circleImage
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    [path addClip];
    [self drawAtPoint:CGPointZero];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
