//
//  ADTableViewVC.m
//  ADPlayer
//
//  Created by 阿蛋 on 17/10/5.
//  Copyright © 2017年 adan. All rights reserved.
//

#import "ADTableViewVC.h"
#import "ADConst.h"
#import "ADPlayer.h"
#import "ADVideoModel.h"
#import <UIImageView+WebCache.h>
#import "ADTopicCell.h"

#define ScreenWidth  [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ADTableViewVC ()<UITableViewDelegate,UITableViewDataSource,ADPlayerDelegate,UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *viedoLists;
@property(nonatomic,strong) ADPlayer *player;
@property (nonatomic,strong) NSIndexPath *currentIndexPath; // 当前播放的cell
@property (nonatomic,assign) BOOL isSmallScreen; // 是否放置在window上
@property(nonatomic,strong) ADTopicCell *currentCell; // 当前cell

@end
static NSString *cellId = @"ADTopicCell";
@implementation ADTableViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isSmallScreen = NO;
    [self loadData];
    self.navigationItem.title = @"ADPlayer";
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"ADTopicCell" bundle:nil] forCellReuseIdentifier:cellId];
    //旋转屏幕通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(getNotification) name:ADTabbarChangeClick object:nil];
}
-(void)getNotification
{
    //1.当前界面不在主窗口上
    if (self.view.window != nil) return;
    //2.如果当前控制器不是allViewController,不要刷新
    if (self.player) {
        ADTopicCell *currentCell = (ADTopicCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
        [currentCell.playButton.superview bringSubviewToFront:currentCell.playButton];
        [self.player releaseplayer];
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
}
//请求数据
-(void)loadData{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"videoData" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *VideoDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *videoList = [VideoDict objectForKey:@"videoList"];
    for (NSDictionary *dataDic in videoList) {
        ADVideoModel *model = [[ADVideoModel alloc]initWithDictionary:dataDic];
        [model setValuesForKeysWithDictionary:dataDic];
        [self.viedoLists addObject:model];
    }
}
/**
 *  旋转屏幕通知
 */
- (void)onDeviceOrientationChange{
    if (self.player==nil||self.player.superview==nil) return;
    //旋转屏幕方向
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)([UIDevice currentDevice].orientation);
    switch (interfaceOrientation) {
            //电池朝上
        case UIInterfaceOrientationPortrait:{
            if (self.isSmallScreen) {
                //放widow上,小屏显示
                [self toSmallScreen];
            }
            [self toCell];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            [self setNeedsStatusBarAppearanceUpdate];
            [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            [self setNeedsStatusBarAppearanceUpdate];
            [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
        }
            break;
        default:
            break;
    }
}
// 滚动的时候小屏幕，放window上显示
-(void)toSmallScreen{
    //放widow上
    [self.player removeFromSuperview];
    [self.player ToSmallScreen];
    [self setNeedsStatusBarAppearanceUpdate];
    self.isSmallScreen = YES;
}
// 当前cell显示
-(void)toCell{
    ADTopicCell *currentCell = (ADTopicCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
    //移除player
    [self.player removeFromSuperview];
    self.player.transform = CGAffineTransformIdentity;
    //回到cell显示
    self.player.frame = currentCell.bounds;
    self.player.playerLayer.frame =  self.player.bounds;
    [currentCell.iconImageView addSubview:self.player];
    [currentCell.iconImageView bringSubviewToFront:self.player];
    [self.player BackToCell];
    //重新设置frame，重新设置layer的frame
    self.player.frame = currentCell.iconImageView.bounds;
    [self setNeedsStatusBarAppearanceUpdate];
    self.isSmallScreen = NO;
}

// 全屏显示
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    //移除player
    [self.player removeFromSuperview];
    self.player.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        self.player.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        self.player.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    //设置frame
    self.player.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    self.player.playerLayer.frame =  CGRectMake(0,0, ScreenHeight,ScreenWidth);
    
    [self.player.downView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(ScreenWidth-40);
        make.width.mas_equalTo(ScreenHeight);
    }];
    
    [self.player.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(0);
        make.width.mas_equalTo(ScreenHeight);
    }];
    
    [self.player.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.player).with.offset((-ScreenHeight/2));
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(30);
        make.top.equalTo(self.player).with.offset(5);
        
    }];
    
    [self.player.titleLB mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.player.topView).with.offset(45);
        make.right.equalTo(self.player.topView).with.offset(-45);
        make.center.equalTo(self.player.topView);
        make.top.equalTo(self.player.topView).with.offset(0);
    }];
    
    [self.player.FailedLB mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(ScreenHeight);
        make.center.mas_equalTo(CGPointMake(ScreenWidth/2-36, -(ScreenWidth/2)));
        make.height.equalTo(@30);
    }];
    
    [self.player.IndicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(CGPointMake(ScreenWidth/2-37, -(ScreenWidth/2-37)));
    }];
    [self.player.FailedLB mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(ScreenHeight);
        make.center.mas_equalTo(CGPointMake(ScreenWidth/2-36, -(ScreenWidth/2)+36));
        make.height.equalTo(@30);
    }];
    [[UIApplication sharedApplication].keyWindow addSubview:self.player];
    
    self.player.fullScreenBtn.selected = YES;
    [self.player bringSubviewToFront:self.player.downView];
}
#pragma mark - 播放器的代理回调

-(void)ClosebuttonClick:(UIButton *)button{
    ADTopicCell *currentCell = (ADTopicCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
    [currentCell.playButton.superview bringSubviewToFront:currentCell.playButton];
    [self.player releaseplayer];
    [self setNeedsStatusBarAppearanceUpdate];
    
}
//点击全屏按钮
-(void)fullScreenClick:(UIButton *)button
{
    if (button.isSelected) {//全屏显示
        [self setNeedsStatusBarAppearanceUpdate];
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }else{
        if (self.isSmallScreen) {
            //放widow上,小屏显示
            [self toSmallScreen];
        }else{
            [self toCell];
        }
    }
}
//播放完成
-(void)finishedPlay{
    ADTopicCell *currentCell = (ADTopicCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
    [currentCell.playButton.superview bringSubviewToFront:currentCell.playButton];
    [self.player releaseplayer];
    [self setNeedsStatusBarAppearanceUpdate];
}
#pragma mark - tableView的Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.viedoLists.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ADTopicCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    [self configCell:cell indexpath:indexPath tableView:tableView];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)configCell:(ADTopicCell *)cell indexpath:(NSIndexPath *)indexpath tableView:(UITableView *)tableView
{
    ADVideoModel *model = self.viedoLists[indexpath.row];
    cell.textLB.text = model.title;
    [cell.playButton addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.playButton.tag = indexpath.row;
    [cell.iconImageView sd_setImageWithURL:[NSURL URLWithString:model.cover] placeholderImage:nil];
    
    // 当播放器的View存在的时候
    if (self.player&&self.player.superview) {
        if (indexpath.row==self.currentIndexPath.row) {
            [cell.playButton.superview sendSubviewToBack:cell.playButton];
        }else{
            [cell.playButton.superview bringSubviewToFront:cell.playButton];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 350;
}

#pragma mark - 播放器播放

- (void)startPlayVideo:(UIButton *)sender
{
    // 获取当前的indexpath
    self.currentIndexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    //获取cell
    if ([UIDevice currentDevice].systemVersion.floatValue>=8||[UIDevice currentDevice].systemVersion.floatValue<7) {
        self.currentCell = (ADTopicCell *)sender.superview.superview;
    }else{
        self.currentCell = (ADTopicCell *)sender.superview.superview.subviews;
    }
    ADVideoModel *model = [self.viedoLists objectAtIndex:sender.tag];
    
    // 当有上一个在播放的时候 点击 就先release
    if (self.player){
        [self.player releaseplayer];
    };
    self.player = [[ADPlayer alloc]initWithFrame:self.currentCell.iconImageView.bounds];
    self.player.delegate = self;
    self.player.VideoURL = model.mp4_url;
    self.player.titleLB.text = model.title;
    
    //block
    __weak typeof(self) weakSelf = self;
    self.player.buttonAction = ^(UIButton *button){
        [weakSelf fullScreenClick:button];
    };
    self.player.ClosebuttonAction = ^(UIButton *button){
        [weakSelf ClosebuttonClick:button];
    };
    self.player.finishedPlay = ^(){
        [weakSelf finishedPlay];
    };
    // 把播放器加到当前cell的imageView上面
    [self.currentCell.iconImageView addSubview:self.player];
    [self.currentCell.iconImageView bringSubviewToFront:self.player];
    [self.currentCell.playButton.superview sendSubviewToBack:self.currentCell.playButton];
    [self.player play];
    [self.tableView reloadData];
}


#pragma mark scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.player==nil)return;
    if (self.player.superview) {
        CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:self.currentIndexPath];
        CGRect rectInSuperview = [self.tableView convertRect:rectInTableView toView:[self.tableView superview]];
        if (rectInSuperview.origin.y<-self.currentCell.iconImageView.frame.size.height||rectInSuperview.origin.y>ScreenHeight-ADNavbarHeight - ADTabBarHeight) {//往上拖动
            //放widow上,小屏显示
            [self toSmallScreen];
        }else{
            [self toCell];
        }
    }
}

- (NSMutableArray *)viedoLists
{
    if (_viedoLists == nil) {
        _viedoLists = [[NSMutableArray alloc] init];
    }
    return _viedoLists;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player releaseplayer];
}

@end
