//
//  FMGVideoPlayView.h
//  02-远程视频播放(AVPlayer)
//
//  Created by apple on 15/8/16.
//  Copyright (c) 2015年 xiaomage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef  void(^backBlock)(void);

@interface FMGVideoPlayView : UIView

+ (instancetype)videoPlayView;

//@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, copy) NSString *urlString;

@property (nonatomic, assign) BOOL isLocalData;
/* 包含在哪一个控制器中 */
@property (nonatomic, weak) UIViewController *contrainerViewController;

/* 播放器 */
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic,copy) backBlock backBlock;

- (void)videoplayViewSwitchOrientation:(BOOL)isFull;

-(void)stopPlayerAndReleasePlayer;
@end
