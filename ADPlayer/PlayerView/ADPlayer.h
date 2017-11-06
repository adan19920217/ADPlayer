//
//  ADPlayer.h
//  ADPlayer
//
//  Created by 阿蛋 on 17/10/27.
//  Copyright © 2017年 adan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Masonry.h"

@import MediaPlayer;
@import AVFoundation;
@import UIKit;

typedef NS_ENUM(NSInteger,ADPlayerState) {
    ADPlayerStateReadToplay,//准备播放
    ADPlayerStateFailed,//失败
    ADPlayerStateCushion,//缓冲中
    ADPlayerStatePlaying,//正在播放
    ADPlayerStatePause,//暂停
    ADPlayerStateFinished//播放结束
};
@class ADPlayer;
@protocol ADPlayerDelegate <NSObject>
@optional

//播放失败
-(void)ADPlayerPlayFailed:(ADPlayer *)adplayer PlayerState:(ADPlayerState)PlayerState;
//准备播放
-(void)ADPlayerReadToPlay:(ADPlayer *)adplayer PlayerState:(ADPlayerState)PlayerState;
@end
//点击全屏按钮
typedef void(^FullScreenbtnClick)(UIButton *button);
//点击关闭按钮
typedef void(^ClosebtnClick)(UIButton *button);
//播放器播放结束
typedef void(^FinishedPlay)();

@interface ADPlayer : UIView
//全屏按钮点击事件
@property (nonatomic,copy) FullScreenbtnClick buttonAction;
//关闭按钮点击事件
@property (nonatomic,copy) ClosebtnClick ClosebuttonAction;
//播放器播放结束事件
@property (nonatomic,copy) FinishedPlay finishedPlay;

//视频信息
@property(nonatomic,copy)NSString *VideoURL;
@property(nonatomic,retain)AVPlayerItem *Item;
@property(nonatomic,retain)AVPlayer *player;
@property(nonatomic,retain)AVPlayerLayer *playerLayer;
@property(nonatomic,weak)id <ADPlayerDelegate> delegate;
@property(nonatomic,assign)ADPlayerState state;
//顶部工具栏
@property(nonatomic,strong)UIView *topView;
@property(nonatomic,strong)UILabel *titleLB;
@property(nonatomic,strong)UIButton *closeBtn;
//底部工具栏
@property(nonatomic,strong)UIView *downView;
@property(nonatomic,strong)UIButton *playPauseBtn;
@property(nonatomic,strong)UIButton *fullScreenBtn;
//屏幕中央
@property(nonatomic,strong)UILabel *FailedLB;
@property(nonatomic,strong)UIActivityIndicatorView *IndicatorView;
//定时器
@property (nonatomic, retain) NSTimer *autoDismissTimer;
//播放
-(void)play;
//暂停
-(void)pause;
//获取当前时间
-(double)GetCurrentTime;
//小屏幕播放
-(void)ToSmallScreen;
//回到cell播放
-(void)BackToCell;
//释放player
-(void)releaseplayer;
@end
