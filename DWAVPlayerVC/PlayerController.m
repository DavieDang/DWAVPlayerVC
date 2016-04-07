//
//  PlayerController.m
//  BGTest_Movieplay
//
//  Created by BingoMacMini on 16/3/25.
//  Copyright © 2016年 BingoMacMini. All rights reserved.
//


#define AVPLAYERVC [PlayerController sharedInstance].player
#define ERRORLIMIT 3

#import "PlayerController.h"
#import "Masonry.h"
#import <AVFoundation/AVFoundation.h>


@interface PlayerController ()

@property(nonatomic,strong)UIButton *button;
@property(nonatomic,strong)AVPlayer *player;

@property(nonatomic,assign)double currentPlayTime;
@property(nonatomic,assign)double nextPlayTime;
@property(nonatomic,assign)double AllTime;
@property(nonatomic,assign)double AllTime2;
@property(nonatomic,strong)NSMutableDictionary *timeDic;
//记录数据的开关
@property (nonatomic,assign) BOOL isOpenRecord;
/**
 *  退出时的保存路径
 */
@property (nonatomic,copy) NSString *savePath;

/**
 *  可变的数组用于保存中断时的时间
 */

@property (nonatomic,strong) NSMutableDictionary *dicStartTime;
//上一次播放的总时间
@property (nonatomic,strong) NSNumber *lastTotalTime;

/**
 *  用一个集合记录播放过的时间
 */

@property (nonatomic,strong) NSMutableSet *playedTime;

@end

@implementation PlayerController


- (AVPlayer *)player{
    if (!_player) {
        
        NSURL *Url = [NSURL URLWithString:@"http://flv2.bn.netease.com/videolib3/1511/26/Wuimb0091/SD/Wuimb0091-mobile.mp4"];
        AVPlayerItem *item  = [AVPlayerItem playerItemWithURL:Url];
        _player = [AVPlayer playerWithPlayerItem:item];
        
        
    }
    return _player;
}

- (UIButton *)button{
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.button setTitle:@"播放视频" forState:0];
        
        
        [self.button setTintColor:[UIColor redColor]];
        self.button.backgroundColor = [UIColor grayColor];
        [self.button addTarget:self action:@selector(gotoplay:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
}
//建立一个单例的播放器

+ (AVPlayerViewController *)sharedInstance{
    
    static AVPlayerViewController *vc = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        vc = [AVPlayerViewController new];
        
        
    });
    return vc;
}


- (NSString *)savePath {
    if (!_savePath) {
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        _savePath = [path stringByAppendingPathComponent:@"starPlay.plist"];
        
    }
    
    return _savePath;
}




- (void)viewDidLoad {
    [super viewDidLoad];

    self.playedTime = [NSMutableSet set];
    self.isOpenRecord = YES;
    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.button];
    
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.top.mas_equalTo(100);
        make.size.mas_equalTo(CGSizeMake(self.view.bounds.size.width, 200));
    }];
    
    
    [self addNotification];

    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"查看时间" forState:0];
    
    [button setTintColor:[UIColor redColor]];
    button.backgroundColor = [UIColor grayColor];
    [button addTarget:self action:@selector(lookatcurrenttime) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.view addSubview:button];
    
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(100);
        make.top.mas_equalTo(400);
        make.size.mas_equalTo(CGSizeMake(100, 50));
    }];

    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setTitle:@"查看保存路径" forState:0];
    
    [button2 setTintColor:[UIColor redColor]];
    button2.backgroundColor = [UIColor grayColor];
    [button2 addTarget:self action:@selector(looklook) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.view addSubview:button2];
    
    [button2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(100);
        make.top.mas_equalTo(500);
        make.size.mas_equalTo(CGSizeMake(100, 50));
    }];

    
    

  
    

}

//查看当前的时间，及统计看视频的时间
- (void)looklook{

    
    
    NSLog(@"看的时间是%.2fs",self.AllTime2);
    NSLog(@"保存路径是%@",self.savePath);
      NSNumber *playedCount = [self transformForm:[PlayerController sharedInstance].player.currentItem.duration];
    NSLog(@"视频的长度%ld",(NSInteger)playedCount);
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)gotoplay:(UIButton *)sender{
    
    [PlayerController sharedInstance].player =self.player;
    [sender addSubview:[PlayerController sharedInstance].view];
    
    [[PlayerController sharedInstance].view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.button);
    }];
    
    
    [self.player play];
    
    [self extractLastTotalTime];
    [[PlayerController sharedInstance].player seekToTime:[self startPlayingTime]];
    
    
 
    

    //相当于添加一个定时器监控播放的状态
    [[PlayerController sharedInstance].player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        
        if (self.isOpenRecord == NO && self.player.rate == 1) {
            self.currentPlayTime = CMTimeGetSeconds(time);
            NSLog(@"正在播放时间是%.2fs",self.currentPlayTime);
            self.isOpenRecord = YES;
            
            
        }
        
        
        if(self.isOpenRecord == YES && self.player.rate == 0){
            NSLog(@"正在暂停播放");
            self.nextPlayTime = CMTimeGetSeconds(self.player.currentTime);
            self.AllTime = fabs(self.nextPlayTime - self.currentPlayTime);
            self.AllTime2 += self.AllTime;
            self.isOpenRecord = NO;
            

            //记录已经看过的点
            for (int i = (int)self.currentPlayTime; i <= (int)self.nextPlayTime; i++) {
                [self.playedTime addObject:[NSNumber numberWithInt:i]];
                
            }
            
            
        }
        
    }];
    
}

- (void)addNotification{
    //给AVplayItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:[PlayerController sharedInstance].player.currentItem];
    
    //播放中断的情况
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playTerminate) name:UIApplicationWillTerminateNotification object:[PlayerController sharedInstance].player.currentItem];
   
}
/**
 *  播放完成记录总时间
 */
- (void)playbackFinished{
    
    NSLog(@"播放完成");
    [self playTerminate];
    
    NSLog(@"%@",[self isSeeOut]);
  
    }


/**
 *  一个CMtime转化为NSNnmmber的方法
 */

- (NSNumber *)transformForm:(CMTime) cmtime{
    
    double doubleTime = CMTimeGetSeconds(cmtime);
    NSNumber *numTime = [NSNumber numberWithDouble:doubleTime];
    
    return numTime;
}

/**
 *  播放中断
 */
- (void)playTerminate{
    
 
    CMTime endTime1 = [PlayerController sharedInstance].player.currentTime;
    NSNumber *endTime2 = [self transformForm:endTime1];
    self.dicStartTime = [NSMutableDictionary dictionary];
    [self.dicStartTime setValue:endTime2 forKey:@"starTime"];
    
    double playedTotalTime = self.AllTime2 + self.lastTotalTime.doubleValue;
    NSNumber *numTotal = [NSNumber numberWithDouble:playedTotalTime];
    [self.dicStartTime setValue:numTotal forKey:@"totalTime"];
    //记录已经看过的点
    for (int i = (int)self.currentPlayTime; i <= (int)endTime2; i++) {
        [self.playedTime addObject:[NSNumber numberWithInt:i]];
        
    }
    
    
    [self.dicStartTime writeToFile:self.savePath atomically:YES];
    
       NSLog(@"播放中断，数据已经保存。。。。。");
    NSLog(@"已经看过的点得个数%ld",self.playedTime.count);
    
}

/**
   设置开始播放的时间
 */

- (CMTime)startPlayingTime{
    
    NSMutableDictionary *startimeDic = [NSMutableDictionary dictionaryWithContentsOfFile:self.savePath];
    NSNumber *startNum = [startimeDic valueForKey:@"starTime"];
    double doubleTime = startNum.doubleValue;
    CMTime cmStarttime = CMTimeMake(doubleTime, 1);
    return cmStarttime;
    
    
    
}
/**
 *  提取上一次播放的总时间保存到当前VC
 */
- (void)extractLastTotalTime{
    
    NSMutableDictionary *startimeDic = [NSMutableDictionary dictionaryWithContentsOfFile:self.savePath];
    NSNumber *startNum = [startimeDic valueForKey:@"totalTime"];
    self.lastTotalTime = startNum;
    
    
}

//判断是否看完了视频
- (NSString *)isSeeOut{
    
   NSNumber *playedCount = [self transformForm:[PlayerController sharedInstance].player.currentItem.duration];
    return (self.playedTime.count >= (NSInteger)playedCount - ERRORLIMIT) ? @"视频已经看完了" : @"视频没有看完";
    
}

//删除监听对象
- (void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark - 监控视频的播放
- (void)lookatcurrenttime{
    
   }







/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
