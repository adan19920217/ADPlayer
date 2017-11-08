# ADPlayer
基于AVPlayer，支持竖屏、横屏,左右滑动调节播放进度以及预缓存等功能
## 测试环境
iOS8.0+ 
Xcode8+
## 示例图片
![cell上播放](https://github.com/adan19920217/ADPlayer/blob/master/Oncell.png)
![小屏幕播放](https://github.com/adan19920217/ADPlayer/blob/master/OnWindow.png)
![全屏播放](https://github.com/adan19920217/ADPlayer/blob/master/fullScreen.png)
## 示例代码
```OC
//单纯使用的时候,只需要初始化,设置代理.设置播放url,设置标题等信息,添加到需要播放的View上即可
self.player = [[ADPlayer alloc]initWithFrame:self.currentCell.iconImageView.bounds];
    self.player.delegate = self;
    self.player.VideoURL = model.mp4_url;
    self.player.titleLB.text = model.title;
   [self.currentCell.iconImageView addSubview:self.player];
   [self.player play];
```
```OC
//如果需要实现实例代码中的小屏播放和cell上播放.首先需要搭建对应的UI环境.然后参照demo实现对应的block方法
    ADVideoModel *model = self.viedoLists[indexpath.row];
    cell.textLB.text = model.title;
    [cell.playButton addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.playButton.tag = indexpath.row;
    //设置占位图片
    [cell.iconImageView sd_setImageWithURL:[NSURL URLWithString:model.cover] placeholderImage:nil];
    // 当播放器的View存在的时候
    if (self.player&&self.player.superview) {
        if (indexpath.row==self.currentIndexPath.row) {
            [cell.playButton.superview sendSubviewToBack:cell.playButton];
        }else{
            [cell.playButton.superview bringSubviewToFront:cell.playButton];
        }
    }
    // 获取当前的indexpath(记录当前播放的cell)
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
    
    //block方法,用于实现全屏和关闭播放器等功能
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
    
    //回到cell显示
    -(void)toCell{
    ADTopicCell *currentCell = (ADTopicCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
    //移除player
    [self.player removeFromSuperview];
    self.player.transform = CGAffineTransformIdentity;
    //回到cell显示
    self.player.frame = currentCell.bounds;
    self.player.playerLayer.frame =  self.player.bounds;
    //代码使用masonry布局,在回到cell之前必须添加到父视图
    [currentCell.iconImageView addSubview:self.player];
    [currentCell.iconImageView bringSubviewToFront:self.player];
    [self.player BackToCell];
    //重新设置frame，重新设置layer的frame
    self.player.frame = currentCell.iconImageView.bounds;
    [self setNeedsStatusBarAppearanceUpdate];
    self.isSmallScreen = NO;
}
