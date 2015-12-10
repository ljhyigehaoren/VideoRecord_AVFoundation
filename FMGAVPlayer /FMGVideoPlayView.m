//
//  FMGVideoPlayView.m
//  02-远程视频播放(AVPlayer)
//
//  Created by apple on 15/8/16.
//  Copyright (c) 2015年 xiaomage. All rights reserved.
//

#import "FMGVideoPlayView.h"
#import "FullViewController.h"
//#import "MacroDefinition.h"

@interface FMGVideoPlayView()

// 播放器的Layer
@property (weak, nonatomic) AVPlayerLayer *playerLayer;

/* playItem */
@property (nonatomic, weak) AVPlayerItem *currentItem;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *fullButton;

// 记录当前是否显示了工具栏
@property (assign, nonatomic) BOOL isShowToolView;

/* 定时器 */
@property (nonatomic, strong) NSTimer *progressTimer;

///* 工具栏的显示和隐藏 */
//@property (nonatomic, strong) NSTimer *showTimer;
//
///* 工具栏展示的时间 */
//@property (assign, nonatomic) NSTimeInterval showTime;

/* 全屏控制器 */
@property (nonatomic, strong) FullViewController *fullVc;

#pragma mark - 监听事件的处理
- (IBAction)playOrPause:(UIButton *)sender;
- (IBAction)switchOrientation:(UIButton *)sender;
- (IBAction)slider;
- (IBAction)startSlider;
- (IBAction)sliderValueChange;

- (IBAction)tapAction:(UITapGestureRecognizer *)sender;
- (IBAction)swipeAction:(UISwipeGestureRecognizer *)sender;
- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender;
@property (weak, nonatomic) IBOutlet UIImageView *forwardImageView;

@property (weak, nonatomic) IBOutlet UIImageView *backImageView;

@end

@implementation FMGVideoPlayView
{
    BOOL isFullScreen;
}

// 快速创建View的方法
+ (instancetype)videoPlayView
{
    return [[[NSBundle mainBundle] loadNibNamed:@"FMGVideoPlayView" owner:nil options:nil] firstObject];
}
- (AVPlayer *)player
{
    if (!_player) {

        // 初始化Player和Layer
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

- (void)awakeFromNib
{
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.imageView.layer addSublayer:self.playerLayer];
    // 设置工具栏的状态
    self.toolView.alpha = 0;
//    self.backButton.alpha = 0;
    self.isShowToolView = NO;
    
    self.forwardImageView.alpha = 0;
    self.backImageView.alpha = 0;
    
    // 设置进度条的内容
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"thumbImage"] forState:UIControlStateNormal];
    
    // 设置按钮的状态
    self.playOrPauseBtn.selected = NO;
    
    [self showToolView:YES];
}

#pragma mark - 观察者对应的方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (AVPlayerItemStatusReadyToPlay == status) {
//            [self removeProgressTimer];
            _timeLabel.text = [self timeString];
            NSLog(@"视屏准备播放");
        }
        else if (AVPlayerStatusUnknown == status)
        {
//            [self removeProgressTimer];
            NSLog(@"视屏处于未知状态");
        }
        else
        {
//            没有网的情况下会加载失败
            NSLog(@"视屏加载失败");
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
//        (监听已经加载的时常)
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"Time Interval:%f",timeInterval);
    }
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}


#pragma mark - 重新布局
- (void)layoutSubviews
{
    [super layoutSubviews];

    self.playerLayer.frame = self.bounds;
  
}

#pragma mark - 设置播放的视频
- (void)setUrlString:(NSString *)urlString
{
    _urlString = urlString;
    
    NSURL *url;
    
    if (_isLocalData) {
        url = [NSURL fileURLWithPath:urlString];
    }
    else{
        url = [NSURL URLWithString:urlString];
    }
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    self.currentItem = item;
    
    [self.player replaceCurrentItemWithPlayerItem:self.currentItem];
    
//    当前播放的状态
    [self.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//    加载的进度
    [self.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
}

// 是否显示工具的View
- (IBAction)tapAction:(UITapGestureRecognizer *)sender {
    [self showToolView:!self.isShowToolView];
//    if (self.isShowToolView) {
//        [self showToolView:YES];
//    }
}

- (IBAction)swipeAction:(UISwipeGestureRecognizer *)sender {
    [self swipeToRight:YES];
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    [self swipeToRight:NO];
}

- (void)swipeToRight:(BOOL)isRight
{
    
    // 1.获取当前播放的时间
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
    
    if (isRight) {
        [UIView animateWithDuration:1 animations:^{
            self.forwardImageView.alpha = 1;
        } completion:^(BOOL finished) {
            self.forwardImageView.alpha = 0;
        }];
        currentTime += 10;
        
    } else {
        [UIView animateWithDuration:1 animations:^{
            self.backImageView.alpha = 1;
        } completion:^(BOOL finished) {
            self.backImageView.alpha = 0;
        }];
        currentTime -= 10;
        
    }
    
    if (currentTime >= CMTimeGetSeconds(self.player.currentItem.duration)) {
        
        currentTime = CMTimeGetSeconds(self.player.currentItem.duration) - 1;
    } else if (currentTime <= 0) {
        currentTime = 0;
    }
    
    [self.player seekToTime:CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    [self updateProgressInfo];
}

//显示工具栏
- (void)showToolView:(BOOL)isShow
{
    if (self.progressSlider.tag == 100) {
        self.progressSlider.tag = 20;
        return;
    
    }
    [UIView animateWithDuration:1.0 animations:^{
        self.toolView.alpha = !self.isShowToolView;
//        self.backButton.alpha = !self.isShowToolView;
        self.isShowToolView = !self.isShowToolView;
    }];
}

// 暂停按钮的监听
- (IBAction)playOrPause:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    if (sender == nil) {
        self.playOrPauseBtn.selected = NO;
    }
    if (sender.selected) {
        [self removeProgressTimer];
        
        [self.player play];

        [self addProgressTimer];
    } else {
        [self.player pause];

        [self removeProgressTimer];
    }
}

#pragma mark - 定时器操作
- (void)addProgressTimer
{
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
}

//移除进度条的计时器
- (void)removeProgressTimer
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

- (void)updateProgressInfo
{
    // 1.更新时间
    self.timeLabel.text = [self timeString];
    
    self.progressSlider.value = CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration);
    NSLog(@"%f",self.progressSlider.value);
    if(self.progressSlider.value == 1)
    {
//        将进度条设置为0
        self.progressSlider.value = 0;
//        设置一个tag值
        self.progressSlider.tag = 100;
//        将当前播放的值设置为0
        [self.player seekToTime:kCMTimeZero];
//        将按钮的状态设置为NO
        self.playOrPauseBtn.selected = NO;
//        工具栏的透明度设置为1;
        self.toolView.alpha = 1;
//        self.backButton.alpha = 1;
//        移除监控进度条的计时器
        [self removeProgressTimer];
//        设置时间展示的Label
        self.timeLabel.text = @"00:00 / 00:00";
        return;
    }
}

- (NSString *)timeString
{
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentTime);
    return [self stringWithCurrentTime:currentTime duration:duration];
}


#pragma mark - 切换屏幕的方向
- (IBAction)switchOrientation:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    [self videoplayViewSwitchOrientation:sender.selected];
}

- (void)videoplayViewSwitchOrientation:(BOOL)isFull
{
    if (isFull) {
        isFullScreen = YES;
        [self.contrainerViewController presentViewController:self.fullVc animated:NO completion:^{
            [self.fullVc.view addSubview:self];
            self.center = self.fullVc.view.center;
            
            [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                self.frame = self.fullVc.view.bounds;
            } completion:nil];
        }];
    } else {
        
//        isFullScreen = NO;
//        [self.fullVc dismissViewControllerAnimated:NO completion:^{
//            [self.contrainerViewController.view addSubview:self];
//            
//            [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
////                旋转屏幕为竖直方向
//                CGAffineTransform portraitTransform = CGAffineTransformMakeRotation(0);
//                self.transform = portraitTransform;
//                if (self.frame.size.width > self.frame.size.height) {
//                    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];                }
//                CGFloat size;
////                发生了旋转
//                if (self.contrainerViewController.view.frame.size.width > self.contrainerViewController.view.frame.size.height) {
//                    size = self.contrainerViewController.view.frame.size.height;
//                }
////                 正常情况下未发生旋转
//                else
//                {
//                    size = self.contrainerViewController.view.frame.size.width;
//                }
//                 self.frame = CGRectMake(0, 0, size, self.contrainerViewController.view.frame.size.height);
//            } completion:nil];
//        }];
    }
}

//返回按钮
- (IBAction)backAction:(id)sender {
    if (isFullScreen)
    {
            //        点击返回按钮返回时要将全屏的按钮的选中属性设置为NO
            isFullScreen = NO;
            _fullButton.selected = NO;
            [self.fullVc dismissViewControllerAnimated:NO completion:^{
                [self.contrainerViewController.view addSubview:self];
                
                [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                    //                旋转屏幕为竖直方向
                    CGAffineTransform portraitTransform = CGAffineTransformMakeRotation(0);
                    self.transform = portraitTransform;
                    if (self.frame.size.width > self.frame.size.height) {
                        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
                    }
                    CGFloat size;
                    //                发生了旋转
                    if (self.contrainerViewController.view.frame.size.width > self.contrainerViewController.view.frame.size.height) {
                        size = self.contrainerViewController.view.frame.size.height;
                    }
                    //                 正常情况下未发生旋转
                    else
                    {
                        size = self.contrainerViewController.view.frame.size.width;
                    }
                    if (_isLocalData) {
                        self.frame = CGRectMake(0, 0, size, self.contrainerViewController.view.frame.size.height);
                    }
                    else{
                        self.frame = CGRectMake(0, 0, size, size*9/16);
                    }
                    
                    
                } completion:nil];
                if (_isLocalData) {
                     self.backBlock();
                }
            }];
    }
    else
    {
        NSLog(@"非全屏下的返回");
        self.backBlock();
    }

}

- (IBAction)slider
{
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    [self.player seekToTime:CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

//开始滑块的时候
- (IBAction)startSlider
{
//    防止在拖动滑块的时候惊醒
    [self removeProgressTimer];
}

//滑块的value值发生改变的时候执行

- (IBAction)sliderValueChange
{
    [self removeProgressTimer];
    
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    self.timeLabel.text = [self stringWithCurrentTime:currentTime duration:duration];
//    当处于播放状态的时候添加进度条的监控计时器
    if ( self.playOrPauseBtn.selected == YES) {
        [self addProgressTimer];
    }
}

//现实当前时间和总时间的label文字计算方式
- (NSString *)stringWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    if (currentTime >= 0 && duration >= 0) {
        NSInteger dMin = duration / 60;
        NSInteger dSec = (NSInteger)duration % 60;
        
        NSInteger cMin = currentTime / 60;
        NSInteger cSec = (NSInteger)currentTime % 60;
        
        NSString *durationString = [NSString stringWithFormat:@"%02ld:%02ld", dMin, dSec];
        NSString *currentString = [NSString stringWithFormat:@"%02ld:%02ld", cMin, cSec];
        
        return [NSString stringWithFormat:@"%@ / %@", currentString, durationString];
    }
    else
    {
        return @"00:00 / 00:00";
    }
   
}

//停止播放释放AVpalyer播放器
-(void)stopPlayerAndReleasePlayer
{
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    [[_player currentItem] removeObserver:self forKeyPath:@"status" context:nil];
    [[_player currentItem] removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];

    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self.player pause];
    self.player = nil;
    [self removeProgressTimer];
    [self removeFromSuperview];
    NSLog(@"释放资源");
    
}

#pragma mark - 懒加载代码
- (FullViewController *)fullVc
{
    if (_fullVc == nil) {
        _fullVc = [[FullViewController alloc] init];
    }
    return _fullVc;
}

@end
