//
//  ViewController.m
//  VideoRecord_AVFoundation
//
//  Created by TianHaoShengShi on 15/10/30.
//  Copyright © 2015年 TianHaoShengShi. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "FMGVideoPlayView.h"
#define  documentPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define fileNmae @"movie.mov"

@interface ViewController ()<AVCaptureFileOutputRecordingDelegate>
{
    BOOL isRecording;
}
@property (nonatomic,strong) UILabel *label;
@property (nonatomic,strong) UIButton *button;
@property (strong,nonatomic) AVCaptureSession *session;
@property (strong,nonatomic) AVCaptureMovieFileOutput *output;
@property (weak, nonatomic) FMGVideoPlayView *playView;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    _label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];
    _label.backgroundColor = [UIColor grayColor];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];
    
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.frame = CGRectMake(0,self.view.bounds.size.height - 50 ,self.view.bounds.size.width , 50);
    _button.backgroundColor = [UIColor grayColor];
    [_button addTarget:self action:@selector(begainVideoRecord:) forControlEvents:UIControlEventTouchUpInside];
    [_button setTitle:@"录制" forState: UIControlStateNormal];
    [self.view addSubview:_button];
//    实例化
    self.session = [[AVCaptureSession alloc]init];
//    设置捕获的视频的质量
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
//    指定的媒体类型
//    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSArray *cameraDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    NSError *error = nil;
//    捕获输入对象（摄像头）(firstObject为后置摄像头  lastObject为前置摄像头)
    AVCaptureDeviceInput *camera = [AVCaptureDeviceInput deviceInputWithDevice:[cameraDevice lastObject] error:&error];
//    设置媒体类型为音频
    AVCaptureDevice *micDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
//    捕获音频对象（麦克风）
    AVCaptureDeviceInput *mic = [AVCaptureDeviceInput deviceInputWithDevice:micDevice error:&error];
    
    if (error || !camera || !mic) {
        NSLog(@"Input Error");
    }
    else
    {
//        添加进入捕捉的会话中
        [self.session addInput:camera];
//        到这崩溃
        [self.session addInput:mic];
    }
//    实例化输出的对象
    self.output = [[AVCaptureMovieFileOutput alloc]init];
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    }
    
    AVCaptureVideoPreviewLayer *previewlayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    
    previewlayer.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64-50);
    [self.view.layer insertSublayer:previewlayer atIndex:0];
    [self.session startRunning];
    isRecording = NO;
    self.label.text = @"";
}

-(void)begainVideoRecord:(UIButton *)button
{
    if (!isRecording) {
        [self.button setTitle:@"停止" forState:UIControlStateNormal];
        self.label.text = @"录制中....";
        isRecording = YES;
        NSURL *fileURL = [self fileURL];
        [self.output startRecordingToOutputFileURL:fileURL recordingDelegate:self];
    }
    else
    {
        [self.button setTitle:@"录制" forState:UIControlStateNormal];
        self.label.text = @"停止";
        [self.output stopRecording];
        isRecording = NO;
    }
}

//录制视频的在沙盒中的文件路径
-(NSURL *)fileURL
{
   NSString *path =  [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:fileNmae]];
    NSURL *outputURL = [[NSURL alloc]initFileURLWithPath:path];
    NSFileManager *manager = [[NSFileManager alloc]init];
    if ([manager  fileExistsAtPath:path]) {
        [manager removeItemAtPath:path error:nil];
    }
    return outputURL;
}

//拍摄成功之后开始播放
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"拍摄成功");
    
    FMGVideoPlayView *playView = [FMGVideoPlayView videoPlayView];
    _playView = playView;
    playView.backBlock = ^void()
    {
        self.navigationController.navigationBarHidden = NO;
        [_playView stopPlayerAndReleasePlayer];
        [_playView removeFromSuperview];
    };
    
   NSString *audioPath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:fileNmae]];
    
    NSLog(@"%@",audioPath);
    //         为本地的视屏
    playView.isLocalData = YES;
    // 视频资源路径
    [playView setUrlString:audioPath];
    //设置播放器的View大小
    playView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    // 添加到当前控制器的view上
    [self.view addSubview:playView];
    playView.backgroundColor = [UIColor grayColor];
    // 指定一个作为播放的控制器
    playView.contrainerViewController = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
