//
//  ADCollectionViewController.m
//  ADPlayer
//
//  Created by 阿蛋 on 17/10/3.
//  Copyright © 2017年 adan. All rights reserved.
//

#import "ADCollectionViewController.h"
#import "ADHomeViewCell.h"
#import "ADPlayer.h"
#import "ADVideoModel.h"
#import <UIImageView+WebCache.h>
#import "ADConst.h"

#define ScreenWidth  [[UIScreen mainScreen] bounds].size.width
// 屏幕的高
#define ScreenHeight [[UIScreen mainScreen] bounds].size.height
@interface ADCollectionViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,ADPlayerDelegate,UIScrollViewDelegate>
@property(nonatomic,strong)UICollectionView *collectionView;
@property(nonatomic,strong)NSMutableArray *dataArr;
@property(nonatomic,strong)ADPlayer *player;
@property (nonatomic,strong) NSIndexPath *currentIndexPath; // 当前播放的cell
@property (nonatomic,strong) NSIndexPath *previousIndexPath;
@property (nonatomic,assign) BOOL isSmallScreen; // 是否放置在window上
@property(nonatomic,strong) ADHomeViewCell *currentCell; // 当前cell
@property(nonatomic,strong) ADHomeViewCell *previousCell;
@property(nonatomic,assign) NSInteger previousIndex;

@end

@implementation ADCollectionViewController

static NSString * const reuseIdentifier = @"Cell";
-(NSMutableArray *)dataArr
{
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.isSmallScreen = NO;
    [self setupCollectionView];
    [self loadData];
    self.navigationItem.title = @"ADCollectionView";
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(getNotification) name:ADTabbarChangeClick object:nil];
}
-(void)getNotification
{
    //1.当前界面不在主窗口上
    if (self.view.window != nil) return;
    //2.如果当前控制器不是allViewController,不要刷新
    if (self.player) {
        ADHomeViewCell *currentCell = (ADHomeViewCell *)[self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
        [currentCell.iconView.superview bringSubviewToFront:currentCell.playButton];
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
        [self.dataArr addObject:model];
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
    ADHomeViewCell *currentCell = (ADHomeViewCell *)[self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
    // 每次切换的时候都要先移除掉
    [self.player removeFromSuperview];
    self.player.transform = CGAffineTransformIdentity;
    //回到cell显示
    self.player.frame = currentCell.bounds;
    self.player.playerLayer.frame =  self.player.bounds;
    [currentCell.iconView addSubview:self.player];
    [currentCell.iconView bringSubviewToFront:self.player];
    [self.player BackToCell];
    //重新设置frame，重新设置layer的frame
    self.player.frame = currentCell.iconView.bounds;
    [self setNeedsStatusBarAppearanceUpdate];
    self.isSmallScreen = NO;
}
// 全屏显示
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    // 先移除
    [self.player removeFromSuperview];
    self.player.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        self.player.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        self.player.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    // 重新设置frame
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
///播放器事件
-(void)ClosebuttonClick:(UIButton *)button{
    ADHomeViewCell *currentCell = (ADHomeViewCell *)[self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
    [currentCell.iconView.superview bringSubviewToFront:currentCell.playButton];
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
    ADHomeViewCell *currentCell = (ADHomeViewCell *)[self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
    [currentCell.iconView.superview bringSubviewToFront:currentCell.playButton];
    [self.player releaseplayer];
    [self setNeedsStatusBarAppearanceUpdate];
}


-(void)setupCollectionView{
        //1.流水布局
        UICollectionViewFlowLayout *flowlayout = [[UICollectionViewFlowLayout alloc]init];
        //左右间距，上下间距
        flowlayout.minimumInteritemSpacing = 15;
        flowlayout.minimumLineSpacing = 15;
    
        self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight) collectionViewLayout:flowlayout];
        self.collectionView.backgroundColor = [UIColor whiteColor];
        [self.collectionView registerNib:[UINib nibWithNibName:@"ADHomeViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:reuseIdentifier];
        
        //设置item大小
        flowlayout.itemSize = CGSizeMake((ScreenWidth - 45)/2,2 *(ScreenWidth - 45)/5);
        //设置上左下右的间距
        flowlayout.sectionInset = UIEdgeInsetsMake(7.5, 15, 7.5, 15);
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        [self.view addSubview:self.collectionView];
}
#pragma mark--数据源方法
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArr.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ADHomeViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    [self configCell:cell indexpath:indexPath collectionView:collectionView];
    return cell;
}
- (void)configCell:(ADHomeViewCell *)cell indexpath:(NSIndexPath *)indexpath collectionView:(UICollectionView *)collectionView
{
    ADVideoModel *model = self.dataArr[indexpath.row];
    cell.nameLB.text = model.title;
    [cell.playButton addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.playButton.tag = indexpath.row;
    [cell.iconView sd_setImageWithURL:[NSURL URLWithString:model.cover] placeholderImage:nil];
}
//开始播放
- (void)startPlayVideo:(UIButton *)sender
{
    self.previousIndexPath = [NSIndexPath indexPathForItem:_previousIndex inSection:0];
    self.previousCell = (ADHomeViewCell *)[self.collectionView cellForItemAtIndexPath:self.previousIndexPath];
    // 当有上一个在播放的时候 点击 就先release
    if (self.player){
        [self.player releaseplayer];
        [self.previousCell.playButton.superview bringSubviewToFront:self.previousCell.playButton];
    };
    _previousIndex = sender.tag;
    // 获取这一点的indexPath
    self.currentIndexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    self.currentCell = (ADHomeViewCell *)[self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
    ADVideoModel *model = [self.dataArr objectAtIndex:sender.tag];
    self.player = [[ADPlayer alloc]initWithFrame:self.currentCell.iconView.bounds];
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
    [self.currentCell.iconView addSubview:self.player];
    [self.currentCell.iconView bringSubviewToFront:self.player];
    [self.currentCell.playButton.superview sendSubviewToBack:self.currentCell.playButton];
    [self.player play];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player releaseplayer];
}


#pragma mark scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.player==nil)return;
    if (self.player.superview) {
    CGRect rectInTableView = [_collectionView convertRect:self.currentCell.frame toView:_collectionView];
    CGRect rectInSuperview = [self.collectionView convertRect:rectInTableView toView:[self.collectionView superview]];
    if (rectInSuperview.origin.y<-self.currentCell.iconView.frame.size.height||rectInSuperview.origin.y>ScreenHeight-ADNavbarHeight - ADStatusBarH -ADTabBarHeight) {//往上拖动
        //放widow上,小屏显示
        [self toSmallScreen];
    }else{
        [self toCell];
     }
    }
}
@end
