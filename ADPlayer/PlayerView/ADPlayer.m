//
//  ADPlayer.m
//  ADPlayer
//
//  Created by 阿蛋 on 17/10/27.
//  Copyright © 2017年 adan. All rights reserved.
//

#import "ADPlayer.h"
#import "ADConst.h"

#define ADScreenWidth  [UIScreen mainScreen].bounds.size.width
#define ADScreenHeight [UIScreen mainScreen].bounds.size.height
/*这种声明方式可以在编译的时候创建一个唯一的指针
 */
static void *ADPlayerViewContext = &ADPlayerViewContext;
@interface ADPlayer()<UIGestureRecognizerDelegate>
//触碰屏幕的起点
@property(nonatomic,assign)CGPoint beginPoint;
//触碰屏幕的终点.
@property(nonatomic,assign)CGPoint endPoint;
//用于转换时间格式
@property (nonatomic, strong)NSDateFormatter *dateFormatter;
//监听播放器状态的监听者
@property (nonatomic ,strong) id playbackTimeObserver;

//点击视频进度条修改播放时间的手势
@property (nonatomic, strong) UITapGestureRecognizer *tap;
//临时变量,记录当前触碰的第一个点
@property (nonatomic, assign) CGPoint originalPoint;
//是否正在拖拽进度条
@property (nonatomic, assign) BOOL isDragingSlider;

//显示播放时间的UILabel
@property (nonatomic,strong) UILabel        *leftTimeLabel;
@property (nonatomic,strong) UILabel        *rightTimeLabel;
//视频进度条
@property (nonatomic,strong) UISlider       *progressSlider;
//缓冲的进度条
@property (nonatomic,strong) UIProgressView *loadingProgress;
@end
@implementation ADPlayer
{
    //记录单击手势
    UITapGestureRecognizer* HideTopOrBottomViewTap;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

//三种创建方法
-(instancetype)init{
    self = [super init];
    if (self) {
        [self initADPlayer];
    }
    return self;
}
- (void)awakeFromNib
{
    [self initADPlayer];
}
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initADPlayer];
    }
    return self;
}
//懒加载属性
-(UILabel *)FailedLB{
    if (_FailedLB==nil) {
        _FailedLB = [[UILabel alloc]init];
        _FailedLB.textColor = [UIColor whiteColor];
        _FailedLB.textAlignment = NSTextAlignmentCenter;
        _FailedLB.text = @"视频加载失败";
        _FailedLB.hidden = YES;
        [self addSubview:_FailedLB];
        
        [_FailedLB mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.equalTo(self);
            make.height.equalTo(@30);
            
        }];
    }
    return _FailedLB;
}
// 懒加载formmater对象,用于后面转换秒数为时/分/秒格式
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

//设置当前播放item
-(void)setItem:(AVPlayerItem *)Item
{
    //如果已经存在一个item,移除所有的item
    if (_Item) {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_Item];
        [_Item removeObserver:self forKeyPath:@"status"];
        [_Item removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_Item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_Item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        _Item = nil;
    }
    _Item = Item;
    if (_Item) {
        [_Item addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionNew
                          context:ADPlayerViewContext];
        [_Item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:ADPlayerViewContext];
        // 缓冲区空了，需要等待数据
        [_Item addObserver:self forKeyPath:@"playbackBufferEmpty" options: NSKeyValueObservingOptionNew context:ADPlayerViewContext];
        // 缓冲区有足够数据可以播放了
        [_Item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options: NSKeyValueObservingOptionNew context:ADPlayerViewContext];
        [self.player replaceCurrentItemWithPlayerItem:_Item];
        // 添加视频播放结束通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_Item];
    }
}
-(void)initADPlayer{
    self.backgroundColor = [UIColor blackColor];
    //顶部View
    self.topView = [[UIView alloc]init];
    self.topView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
    [self addSubview:self.topView];
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(0);
        make.right.equalTo(self).offset(0);
        make.height.mas_equalTo(40);
        make.top.equalTo(self).offset(0);
    }];
    //加载器
    self.IndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:self.IndicatorView];
    [self.IndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    [self.IndicatorView startAnimating];
    
    //底部View
    self.downView = [[UIView alloc]init];
    self.downView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
    [self addSubview:self.downView];
    [self.downView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(0);
        make.right.equalTo(self).offset(0);
        make.bottom.equalTo(self).offset(0);
        make.height.mas_equalTo(40);
    }];
    [self setAutoresizesSubviews:NO];
    //底部View上的控件
    self.playPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [self.playPauseBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateSelected];
    [self.downView addSubview:self.playPauseBtn];
    self.playPauseBtn.showsTouchWhenHighlighted = YES;
    [self.playPauseBtn addTarget:self action:@selector(playorPauseClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.playPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.downView).offset(0);
        make.bottom.equalTo(self.downView).offset(0);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
    //底部进度条
    self.progressSlider = [[UISlider alloc]init];
    //滑块最小值
    self.progressSlider.minimumValue = 0.0;
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    //小于滑块当前值的颜色
    self.progressSlider.minimumTrackTintColor = [UIColor orangeColor];
    self.progressSlider.maximumTrackTintColor = [UIColor clearColor];
    //滑块初始值
    self.progressSlider.value = 0.0;
    [self.progressSlider addTarget:self action:@selector(DragSlider:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(ClickSlider:) forControlEvents:UIControlEventTouchUpInside];
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickTpaGes:)];
    self.tap.delegate = self;
    [self.progressSlider addGestureRecognizer:self.tap];
    [self.downView addSubview:self.progressSlider];
    self.progressSlider.backgroundColor = [UIColor clearColor];
    //autoLayout slider
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.downView).with.offset(45);
        make.right.equalTo(self.downView).with.offset(-45);
        make.center.equalTo(self.downView);
    }];
    
    //缓冲进度
    self.loadingProgress = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.loadingProgress.progressTintColor = [UIColor clearColor];
    //已缓冲颜色
    self.loadingProgress.trackTintColor = [UIColor lightGrayColor];
    [self.downView addSubview:self.loadingProgress];
    [self.loadingProgress setProgress:0.0 animated:NO];
    [self.loadingProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.progressSlider);
        make.right.equalTo(self.progressSlider);
        make.center.equalTo(self.progressSlider);
    }];
    [self.downView sendSubviewToBack:self.loadingProgress];
    
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullScreenBtn.showsTouchWhenHighlighted = YES;
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"nonfullscreen"] forState:UIControlStateSelected];
    [self.downView addSubview:self.fullScreenBtn];
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.downView).offset(0);
        make.bottom.equalTo(self.downView).offset(0);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
    //初始时间
    self.leftTimeLabel = [[UILabel alloc]init];
    self.leftTimeLabel.textColor = [UIColor whiteColor];
    self.leftTimeLabel.backgroundColor = [UIColor clearColor];
    self.leftTimeLabel.font = [UIFont systemFontOfSize:11];
    [self.downView addSubview:self.leftTimeLabel];
    [self.leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.downView).offset(45);
        make.right.equalTo(self.downView).offset(-45);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.downView).offset(0);
    }];
    
    //视频总时间
    self.rightTimeLabel = [[UILabel alloc]init];
    self.rightTimeLabel.textAlignment = NSTextAlignmentRight;
    self.rightTimeLabel.textColor = [UIColor whiteColor];
    self.rightTimeLabel.backgroundColor = [UIColor clearColor];
    self.rightTimeLabel.font = [UIFont systemFontOfSize:11];
    [self.downView addSubview:self.rightTimeLabel];
    //autoLayout timeLabel
    [self.rightTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.downView).with.offset(45);
        make.right.equalTo(self.downView).with.offset(-45);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.downView).with.offset(0);
    }];
    
    //关闭按钮
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeBtn.showsTouchWhenHighlighted = YES;
    [_closeBtn addTarget:self action:@selector(colseTheVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:_closeBtn];
    //autoLayout _closeBtn
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topView).with.offset(5);
        make.height.mas_equalTo(30);
        make.top.equalTo(self.topView).with.offset(5);
        make.width.mas_equalTo(30);
        
    }];
    //titleLabel
    self.titleLB = [[UILabel alloc]init];
    self.titleLB.textAlignment = NSTextAlignmentCenter;
    self.titleLB.textColor = [UIColor whiteColor];
    self.titleLB.backgroundColor = [UIColor clearColor];
    self.titleLB.font = [UIFont systemFontOfSize:17.0];
    [self.topView addSubview:self.titleLB];
    //autoLayout titleLabel
    [self.titleLB mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topView).with.offset(45);
        make.right.equalTo(self.topView).with.offset(-45);
        make.center.equalTo(self.topView);
        make.top.equalTo(self.topView).with.offset(0);
        
    }];
    [self bringSubviewToFront:self.IndicatorView];
    [self bringSubviewToFront:self.downView];
    
    //单击手势:显示或隐藏系统的标题等所在的topView或者时间等所在的downView
    HideTopOrBottomViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(HideTopOrBottomViewClick:)];
    HideTopOrBottomViewTap.numberOfTapsRequired = 1; // 单击
    HideTopOrBottomViewTap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:HideTopOrBottomViewTap];
}
/*关于底部View的事件*/
//点击播放暂停按钮
-(void)playorPauseClick:(UIButton *)button{
    if (self.player.rate != 1.f) {
        button.selected = NO;
        NSLog(@"内部开始播放");
        [self.player play];
    } else {
        button.selected = YES;
        NSLog(@"内部暂停播放");
        [self.player pause];
    }
}
//获取当前视频时间
-(double)GetCurrentTime{
    if (self.player) {
        return CMTimeGetSeconds([self.player currentTime]);
    }else{
        return 0.0;
    }
}
//获取视频全部时间
-(double)AllVideoTime{
    AVPlayerItem *item = self.player.currentItem;
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        //参数item.asset.duration视频的总时间
        return CMTimeGetSeconds(item.asset.duration);
    }else{
        return 0.0;
    }
}
/*进度条*/
//1.拖拽进度条
-(void)DragSlider:(UISlider *)slider{
    self.isDragingSlider = YES;
}
//2.点击了进度条的某一点
-(void)ClickSlider:(UISlider *)slider{
    self.isDragingSlider = NO;
    //第一个参数:当前秒数.第二个参数:每秒多少帧
    [self.player seekToTime:CMTimeMakeWithSeconds(slider.value, _Item.currentTime.timescale)];
}
//3.点击视频进度条改变进度的手势事件
-(void)clickTpaGes:(UITapGestureRecognizer *)tap
{
    //locationinView获取当前点击点的坐标
    CGPoint clickPoint = [tap locationInView:self.progressSlider];
    CGFloat value = (self.progressSlider.maximumValue - self.progressSlider.minimumValue) * (clickPoint.x/self.progressSlider.frame.size.width);
    //设置滑块的进度
    [self.progressSlider setValue:value animated:YES];
    //设置视频的进度
    [self.player seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value, self.Item.currentTime.timescale)];
}
//全屏按钮点击事件
-(void)fullScreenClick:(UIButton *)button
{
    button.selected = !button.selected;
    if (self.buttonAction) {
        // 调用block传入参数
        self.buttonAction(button);
    }
}
//关闭播放器
-(void)colseTheVideo:(UIButton *)button{
    if (self.ClosebuttonAction) {
        self.ClosebuttonAction(button);
    }
}
//单击手势,点击屏幕显示或隐藏topView/DownView
-(void)HideTopOrBottomViewClick:(UITapGestureRecognizer *)ges{
    //取消之前的动作
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissDownView) object:nil];
    //删除之前的timer
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    self.autoDismissTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(dismissDownView) userInfo:nil repeats:YES];
    // 创建定时器并加到runloop中,定时器是使用defaultRunLoopMode
    [[NSRunLoop currentRunLoop]addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    [UIView animateWithDuration:0.5 animations:^{
        if (self.downView.alpha == 0.0) {
            self.downView.alpha = 1.0;
            self.closeBtn.alpha = 1.0;
            self.topView.alpha = 1.0;
            
        }else{
            self.downView.alpha = 0.0;
            self.closeBtn.alpha = 0.0;
            self.topView.alpha = 0.0;
            
        }
    }];
}
//隐藏底部View
-(void)dismissDownView{
  if(self.player.rate == 1.0){//正在播放
        if (self.downView.alpha == 1.0) {
            [UIView animateWithDuration:0.5 animations:^{
                self.downView.alpha = 0.0;
                self.topView.alpha = 0.0;
                self.closeBtn.alpha = 0.0;
            }];
        }
    }
}
//视频播放完成的通知
-(void)moviePlayDidEnd:(NSNotification *)notification{
    self.state = ADPlayerStateFinished;
    if (self.finishedPlay) {
        self.finishedPlay();
    }
}
//设置视频URL
-(void)setVideoURL:(NSString *)VideoURL{
    _VideoURL = VideoURL;
    //设置player的参数
    self.Item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:VideoURL]];
    self.player = [AVPlayer playerWithPlayerItem:_Item];
    //AVPlayerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.layer.bounds;
    //ADPlayer视频的默认填充模式，AVLayerVideoGravityResizeAspect // 全屏幕放大，但是比例失调了
    // AVLayerVideoGravityResizeAspectFill 等比例拉伸，会部分裁减掉
    // AVLayerVideoGravityResizeAspect 拉伸一边，会有留白
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.layer insertSublayer:_playerLayer atIndex:0];
    //缓冲中
    self.state = ADPlayerStateCushion;
    [_closeBtn setImage:[UIImage imageNamed:@"play_back.png"] forState:UIControlStateNormal];
    [_closeBtn setImage:[UIImage imageNamed:@"play_back.png"] forState:UIControlStateSelected];
}
//设置播放器的状态
-(void)setState:(ADPlayerState)state{
    _state = state;
    //控制菊花隐藏
    if (state == ADPlayerStateCushion) {
        [self.IndicatorView startAnimating];
    }else if(state == ADPlayerStatePlaying){
        [self.IndicatorView stopAnimating];
    }else if(state == ADPlayerStateReadToplay){
        [self.IndicatorView stopAnimating];
    }
    else{
        [self.IndicatorView stopAnimating];
    }
}
//添加全部的监听事件KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (context == ADPlayerViewContext) {
        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerStatusUnknown:
                    [self.loadingProgress setProgress:0.0 animated:NO];
                    self.state = ADPlayerStateCushion;
                    [self.IndicatorView startAnimating];
                    break;
                case AVPlayerStatusReadyToPlay:
                {
                    self.state = ADPlayerStateReadToplay;
                    // 双击的 Recognizer
                    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(DoubleClick:)];
                    doubleTap.numberOfTapsRequired = 2; // 双击
                    //双击手势进行的时候取消单击手势
                    [HideTopOrBottomViewTap requireGestureRecognizerToFail:doubleTap];
                    [self addGestureRecognizer:doubleTap];
                    //如果视频时长不为空
                    if (CMTimeGetSeconds(_Item.duration)) {
                        self.progressSlider.maximumValue = CMTimeGetSeconds(self.player.currentItem.duration);
                    }
                    //监听播放状态
                    [self initTimer];
                    //5秒后隐藏视图
                    if (self.autoDismissTimer ==nil) {
                        self.autoDismissTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(dismissDownView) userInfo:nil repeats:YES];
                        [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
                    }
                    
                    if (self.delegate&&[self.delegate respondsToSelector:@selector(ADPlayerReadToPlay:PlayerState:)]) {
                        [self.delegate ADPlayerReadToPlay:self PlayerState:ADPlayerStateReadToplay];
                    }
                    [self.IndicatorView stopAnimating];
                }
                    break;
                case AVPlayerStatusFailed:
                {
                    self.state = ADPlayerStateFailed;
                    if (self.delegate&&[self.delegate respondsToSelector:@selector(ADPlayerPlayFailed:PlayerState:)]) {
                        [self.delegate ADPlayerPlayFailed:self PlayerState:ADPlayerStateFailed];
                    }
                    NSError *error = [self.player.currentItem error];
                    if (error) {
                        self.FailedLB.hidden = NO;
                        [self bringSubviewToFront:self.FailedLB];
                        [self.IndicatorView stopAnimating];
                    }
                }
                    break;
            }
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            // 计算缓冲进度
            NSTimeInterval timeInterval = [self availableDuration];
            // 总进度
            CMTime duration             = self.Item.duration;
            // 总进度时间
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            //缓冲颜色
            self.loadingProgress.progressTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
            // 设置缓冲的进度
            [self.loadingProgress setProgress:timeInterval / totalDuration animated:NO];
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            // 缓冲为空的时候
            [self.IndicatorView startAnimating];
            // 当缓冲是空的时候 5秒之后进行播放
            if (self.Item.playbackBufferEmpty) {
                self.state = ADPlayerStateCushion;
                [self loadedTimeRanges];
            }
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            [self.IndicatorView stopAnimating];
            // 缓冲好了,并且当前状态为缓冲中,将状态改为正在播放
            if (self.Item.playbackLikelyToKeepUp && self.state == ADPlayerStateCushion){
                self.state = ADPlayerStatePlaying;
            }
        }
    }
}
//双击事件
-(void)DoubleClick:(UITapGestureRecognizer *)DoubleGes{
    //如果在暂停
    if (self.player.rate != 1.f) {
            [self.player play];
            self.playPauseBtn.selected = NO;
        }else {
            [self.player pause];
            self.playPauseBtn.selected = YES;
        }
    [UIView animateWithDuration:0.5 animations:^{
        self.downView.alpha = 1.0;
        self.topView.alpha = 1.0;
        self.closeBtn.alpha = 1.0;
    } completion:^(BOOL finish){
        
    }];
}
//创建定时器,每秒钟刷新Slider
-(void)initTimer{
    double interval = .1f;
    CMTime playerDuration = [self playerItemDuration];
    //检测时间是否合法
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        CGFloat width = CGRectGetWidth([self.progressSlider bounds]);
        interval = 0.5f * duration / width;
    }
    __weak typeof(self) weakSelf = self;
    // 每秒钟调用这个方法进度条
    self.playbackTimeObserver =  [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0, NSEC_PER_SEC)  queue:dispatch_get_main_queue()
                        usingBlock:^(CMTime time){
                        [weakSelf syncScrubber];
    }];
}
// 每秒钟更新进度条
- (void)syncScrubber{
    CMTime playerDuration = [self playerItemDuration];
    // CMTime是否可用的宏
    if (CMTIME_IS_INVALID(playerDuration)){
        self.progressSlider.minimumValue = 0.0;
        return;
    }
    // 获取事件
    double duration = CMTimeGetSeconds(playerDuration);
    // 有限的事件
    if (isfinite(duration)){
        // 最小值 固定
        float minValue = [self.progressSlider minimumValue];
        // 最大值 固定
        float maxValue = [self.progressSlider maximumValue];
        // 当前时间
        double nowTime = CMTimeGetSeconds([self.player currentTime]);
        // 剩下的时间
        double remainTime = duration-nowTime;
        // 转换时间
        self.leftTimeLabel.text = [self convertTime:nowTime];
        self.rightTimeLabel.text = [self convertTime:remainTime];
        if (self.isDragingSlider==YES) {//拖拽slider中，不更新slider的值
        }else if(self.isDragingSlider==NO){
            //更新slider值
            [self.progressSlider setValue:(maxValue - minValue) * nowTime / duration + minValue];
        }
    }
}
// 转换时间为时/分/秒的格式
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    //超过3600秒/1小时
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *newTime = [[self dateFormatter] stringFromDate:d];
    return newTime;
}
//获取视频最大的时间值
- (CMTime)playerItemDuration{
    AVPlayerItem *playerItem = _Item;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}
//计算缓冲时间
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [_Item loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}
- (void)loadedTimeRanges
{
    self.state = ADPlayerStateCushion;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self play];
        [self.IndicatorView stopAnimating];
    });
}
//点击开始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    for(UITouch *touch in event.allTouches) {
        self.beginPoint = [touch locationInView:self];
    }
    //记录下第一个点的位置
    self.originalPoint = self.beginPoint;
}
//滑动事件
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    for(UITouch *touch in event.allTouches) {
        self.endPoint = [touch locationInView:self];
    }
        self.progressSlider.value -= (self.beginPoint.x - self.endPoint.x);
        [self.player seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value, self.Item.currentTime.timescale)];
        //滑动的时候如果暂停了.自动播放
        if (self.player.rate != 1.f) {
            self.playPauseBtn.selected = NO;
            [self.player play];
        }
    self.beginPoint = self.endPoint;
}
//结束滑动
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.beginPoint = self.endPoint = CGPointZero;
}
//移除观察者和通知
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self.player pause];
    [self.player removeTimeObserver:self.playbackTimeObserver];
    
    //移除观察者
    [_Item removeObserver:self forKeyPath:@"status"];
    [_Item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_Item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_Item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    [self.playerLayer removeFromSuperlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    self.Item = nil;
    self.playPauseBtn = nil;
    self.playerLayer = nil;
    self.autoDismissTimer = nil;
}
//播放事件
-(void)play{
    [self playorPauseClick:self.playPauseBtn];
}
//暂停事件
-(void)pause{
    [self playorPauseClick:self.playPauseBtn];
}
//回到小屏幕播放
-(void)ToSmallScreen{
    [UIView animateWithDuration:0.5f animations:^{
        self.transform = CGAffineTransformIdentity;
        // 设置window上的位置
        self.frame = CGRectMake(ADScreenWidth/2,ADScreenHeight - ADTabBarHeight + 40 -(ADScreenWidth/2)*0.75, ADScreenWidth/2, (ADScreenWidth/2)*0.75);
        self.playerLayer.frame =  self.bounds;
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        [self.downView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.right.equalTo(self).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(self).with.offset(0);
        }];
        [self.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.right.equalTo(self).with.offset(0);
            make.height.mas_equalTo(40);
            make.top.equalTo(self).with.offset(0);
        }];
        [self.titleLB mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topView).with.offset(45);
            make.right.equalTo(self.topView).with.offset(-45);
            make.center.equalTo(self.topView);
            make.top.equalTo(self.topView).with.offset(0);
        }];
        [self.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(self).with.offset(5);
            
        }];
        [self.FailedLB mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.equalTo(self);
            make.height.equalTo(@30);
        }];
        
    }completion:^(BOOL finished) {
        self.fullScreenBtn.selected = NO;
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self];
    }];
}
//回到原始位置
-(void)BackToCell{
    [UIView animateWithDuration:0.5f animations:^{
        self.transform = CGAffineTransformIdentity;
        //重新设置frame，重新设置layer的frame
        [self.downView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.right.equalTo(self).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(self).with.offset(0);
        }];
        [self.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(0);
            make.right.equalTo(self).with.offset(0);
            make.height.mas_equalTo(40);
            make.top.equalTo(self).with.offset(0);
        }];
        [self.titleLB mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topView).with.offset(45);
            make.right.equalTo(self.topView).with.offset(-45);
            make.center.equalTo(self.topView);
            make.top.equalTo(self.topView).with.offset(0);
        }];
        [self.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(self).with.offset(5);
        }];
        [self.FailedLB mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.equalTo(self);
            make.height.equalTo(@30);
        }];
    }completion:^(BOOL finished) {
        self.fullScreenBtn.selected = NO;
    }];
}
/**
 *  释放player
 */
-(void)releaseplayer{
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self.player pause];
    
    [self removeFromSuperview];
    [self.playerLayer removeFromSuperlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    self.Item = nil;
    //释放定时器
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    self.playPauseBtn = nil;
    self.playerLayer = nil;
}
@end
