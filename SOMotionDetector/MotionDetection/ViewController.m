//
//  ViewController.m
//  MotionDetection
//
// The MIT License (MIT)
//
// Created by : arturdev
// Copyright (c) 2014 SocialObjects Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import "ViewController.h"
#import "SOMotionDetector.h"
#import "SOStepDetector.h"
#import "UINavigationBar+Awesome.h"
#import "DKCircleButton.h"
#import "SFCountdownView.h"
#import "MZTimerLabel.h"

@interface ViewController ()<SOMotionDetectorDelegate,SFCountdownViewDelegate,MZTimerLabelDelegate>
{
    int stepCount;//总步数
    int lastSecondStepCount;//上一秒总步数
    
    BOOL isStart;//是否开始跑步了
    BOOL isPause;//是否暂停
    BOOL isEnd;//是否结束
    
    DKCircleButton *startButton;// 开始/暂停
    DKCircleButton *endButton;// 结束
    DKCircleButton *continueButton;// 继续
    
    UILabel *stepCountLabel;//步数
    UILabel *costTimeLabel;//时间
    MZTimerLabel *mzCostTimeLabel;
    UILabel *speedLabel;//速度
    
    UILabel *realTimeStepFrequenceLabel;//实时步频
    UILabel *averageStepFrequenceLabel;//平均步频
    
    UILabel *motionTypeLabel;//运动状态(未在页面中显示)
   
    CGFloat buttonCenterY;//按钮中心点的起始高度
    
}



@end

@implementation ViewController

//兼容不同手机屏幕下的尺寸
static inline double con(double number)
{
    return (number/320.0)*SCREEN_WIDTH;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage *image = [UIImage imageNamed:@"ico_beijingtu"];
    self.view.layer.contents = (id) image.CGImage;
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor;

    
    [self initSubViews];
    [self initDetection];
}

#pragma mark - 初始化方法

//初始化页面
-(void)initSubViews{
    
    stepCountLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, con(56))];
    stepCountLabel.font=[UIFont systemFontOfSize:con(50)];
    stepCountLabel.textAlignment=NSTextAlignmentCenter;
    stepCountLabel.textColor=[UIColor whiteColor];
    [self setStepCount:0];
    [self.view addSubview:stepCountLabel];
    stepCountLabel.center=CGPointMake(SCREEN_WIDTH/2, 64 +con(36));
    
    costTimeLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, con(25))];
    costTimeLabel.font=[UIFont systemFontOfSize:con(20)];
    costTimeLabel.textAlignment=NSTextAlignmentCenter;
    costTimeLabel.textColor=MDGreenColor;
    [self.view addSubview:costTimeLabel];
    costTimeLabel.center=CGPointMake(SCREEN_WIDTH/2, CGRectGetMaxY(stepCountLabel.frame)+con(30));
    
    mzCostTimeLabel = [[MZTimerLabel alloc] initWithLabel:costTimeLabel andTimerType:MZTimerLabelTypeStopWatch];
    mzCostTimeLabel.timeFormat = @"HH:mm:ss";
    mzCostTimeLabel.delegate=self;
    
    realTimeStepFrequenceLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/2, con(25))];
    realTimeStepFrequenceLabel.font=[UIFont systemFontOfSize:con(20)];
    realTimeStepFrequenceLabel.textAlignment=NSTextAlignmentCenter;
    realTimeStepFrequenceLabel.textColor=MDGreenColor;
    [self.view addSubview:realTimeStepFrequenceLabel];
    realTimeStepFrequenceLabel.center=CGPointMake(SCREEN_WIDTH/4, CGRectGetMaxY(costTimeLabel.frame)+con(30));
    realTimeStepFrequenceLabel.text=[NSString stringWithFormat:@"%d",0];
    
    
    UILabel *desLabel1=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/2, con(25))];
    
    desLabel1.font=[UIFont systemFontOfSize:con(15)];
    desLabel1.textAlignment=NSTextAlignmentCenter;
    desLabel1.textColor=MDWhiteColor;
    [self.view addSubview:desLabel1];
    desLabel1.center=CGPointMake(SCREEN_WIDTH/4, CGRectGetMaxY(realTimeStepFrequenceLabel.frame)+con(10));
    desLabel1.text=@"实时步频(步/分)";
    
    
    averageStepFrequenceLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/2, con(25))];
    averageStepFrequenceLabel.font=[UIFont systemFontOfSize:con(20)];
    averageStepFrequenceLabel.textAlignment=NSTextAlignmentCenter;
    averageStepFrequenceLabel.textColor=MDGreenColor;
    [self.view addSubview:averageStepFrequenceLabel];
    averageStepFrequenceLabel.center=CGPointMake(SCREEN_WIDTH/4*3, CGRectGetMaxY(costTimeLabel.frame)+con(30));
    averageStepFrequenceLabel.text=[NSString stringWithFormat:@"%d",0];
    
    
    
    UILabel *desLabel2=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/2, con(25))];
    
    desLabel2.font=[UIFont systemFontOfSize:con(15)];
    desLabel2.textAlignment=NSTextAlignmentCenter;
    desLabel2.textColor=MDWhiteColor;
    [self.view addSubview:desLabel2];
    desLabel2.center=CGPointMake(SCREEN_WIDTH/4*3, CGRectGetMaxY(averageStepFrequenceLabel.frame)+con(10));
    desLabel2.text=@"平均步频(步/分)";
    
    //初始化按钮
    [self initButton];
}

//设置步数
-(void)setStepCount:(int)steps{
    //后边默认加"步"
    
    NSString *text=[NSString stringWithFormat:@"%d步",steps];
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:text];
    
    int index=text.length-1;
    
    NSDictionary *attributeDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [UIFont systemFontOfSize:17.0],NSFontAttributeName,
                                   MDGreenColor,NSForegroundColorAttributeName,nil];
    
    [str addAttribute:NSForegroundColorAttributeName value:MDGreenColor range:NSMakeRange(0,index)];
    [str addAttributes:attributeDict range:NSMakeRange(index,text.length-index)];
    
    //设置步数
    stepCountLabel.attributedText=str;

}

//初始化所有的按钮
-(void)initButton{
    buttonCenterY=0.618*SCREEN_HEIGHT;
    CGFloat currentY=CGRectGetMaxY(realTimeStepFrequenceLabel.frame)+con(60)+con(90)/2;
    if (buttonCenterY<currentY) {
        buttonCenterY=currentY;
    }
    
    endButton=[self dkButton:@"结束"];
    [self.view addSubview:endButton];
    endButton.animateTap=NO;
    endButton.center = CGPointMake(SCREEN_WIDTH/2, buttonCenterY);
    endButton.alpha=0;
    [endButton addTarget:self action:@selector(endRunning:) forControlEvents:UIControlEventTouchUpInside];
    
    continueButton=[self dkButton:@"继续"];
    [self.view addSubview:continueButton];
    continueButton.animateTap=NO;
    continueButton.center = CGPointMake(SCREEN_WIDTH/2, buttonCenterY);
    continueButton.alpha=0;
    [continueButton addTarget:self action:@selector(continueRunning:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    startButton=[self dkButton:@"开始"];
    [self.view addSubview:startButton];
    startButton.center = CGPointMake(SCREEN_WIDTH/2, buttonCenterY);
    
    [startButton addTarget:self action:@selector(startRunning:) forControlEvents:UIControlEventTouchUpInside];
}

//初始化运动监听器
-(void)initDetection{
    
//    [SOMotionDetector sharedInstance].motionTypeChangedBlock = ^(SOMotionType motionType) {
//        NSString *type = @"";
//        switch (motionType) {
//            case MotionTypeNotMoving:
//                type = @"状态：停止...";
//                break;
//            case MotionTypeWalking:
//                type = @"状态：走路...";
//                break;
//            case MotionTypeRunning:
//                type = @"状态：奔跑...";
//                break;
//            case MotionTypeAutomotive:
//                type = @"状态：停止...";
//                break;
//        }
//        
//        motionTypeLabel.text = type;
//    };
//    
//    [SOMotionDetector sharedInstance].locationChangedBlock = ^(CLLocation *location) {
//        speedLabel.text = [NSString stringWithFormat:@"%.2f km/h",[SOMotionDetector sharedInstance].currentSpeed * 3.6f];
//    };
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [SOMotionDetector sharedInstance].useM7IfAvailable = YES; //Use M7 chip if available, otherwise use lib's algorithm
    }
    
   
}

//获取圆形按钮
-(DKCircleButton *)dkButton:(NSString *)btnName{
    CGFloat btnWidth=con(90);
    DKCircleButton *btn=[[DKCircleButton alloc]initWithFrame:CGRectMake(0, 0, btnWidth, btnWidth)];
    
    btn.titleLabel.font = [UIFont systemFontOfSize:con(22)];
    
    [btn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateSelected];
    [btn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateHighlighted];
    
    [btn setTitle:btnName forState:UIControlStateNormal];
    [btn setTitle:btnName forState:UIControlStateSelected];
    [btn setTitle:btnName forState:UIControlStateHighlighted];
    btn.backgroundColor=[UIColor colorWithRed:0.29 green:0.59 blue:0.81 alpha:1];
    return btn;
}

//获取跑步前倒数321的view
-(SFCountdownView *)countdownView{
    SFCountdownView *sfCountdownView=[[SFCountdownView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:sfCountdownView];
    sfCountdownView.delegate = self;
    sfCountdownView.backgroundAlpha = 1;
    sfCountdownView.countdownColor = [UIColor whiteColor];
    sfCountdownView.countdownFrom = 3;
    sfCountdownView.finishText = @"Go";
    [sfCountdownView updateAppearance];
    return sfCountdownView;
}


#pragma mark - 按钮方法

- (void) countdownFinished:(SFCountdownView *)view
{
    [startButton setTitle:@"暂停" forState:UIControlStateNormal];
    [startButton setTitle:@"暂停" forState:UIControlStateSelected];
    [startButton setTitle:@"暂停" forState:UIControlStateHighlighted];
    [view removeFromSuperview];
    [self.view setNeedsDisplay];
    
    //开始计时
    [mzCostTimeLabel start];
    
    [[SOMotionDetector sharedInstance] startDetection];
    [[SOStepDetector sharedInstance] startDetectionWithUpdateBlock:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        
        stepCount++;
        [self setStepCount:stepCount];
    }];
     motionTypeLabel.text=@"状态：走路...";
}

-(void)reset{
    [startButton setTitle:@"开始" forState:UIControlStateNormal];
    [startButton setTitle:@"开始" forState:UIControlStateSelected];
    [startButton setTitle:@"开始" forState:UIControlStateHighlighted];
    isEnd=NO;
    isStart=NO;
    isPause=NO;
    //重置其它数据
    [mzCostTimeLabel reset];
    stepCount=0;
    [self setStepCount:0];
    motionTypeLabel.text=@"状态：未开始";
}

-(void)endRunning:(id)sender{
    
    [UIView beginAnimations:@"btnAnimation" context:nil];
    [UIView setAnimationDuration:1.0f];
    [UIView setAnimationDelegate:self];
    continueButton.center=CGPointMake(SCREEN_WIDTH/2, buttonCenterY);
    endButton.center=CGPointMake(SCREEN_WIDTH/2, buttonCenterY);
    continueButton.alpha=0;
    endButton.alpha=0;
    startButton.alpha=1;
    [startButton setTitle:@"重置" forState:UIControlStateNormal];
    [startButton setTitle:@"重置" forState:UIControlStateSelected];
    [startButton setTitle:@"重置" forState:UIControlStateHighlighted];
    isEnd=YES;
    [UIView commitAnimations];
}

-(void)continueRunning:(id)sender{
    [UIView beginAnimations:@"btnAnimation" context:nil];
    [UIView setAnimationDuration:1.0f];
    [UIView setAnimationDelegate:self];
    continueButton.center=CGPointMake(SCREEN_WIDTH/2, buttonCenterY);
    endButton.center=CGPointMake(SCREEN_WIDTH/2, buttonCenterY);
    continueButton.alpha=0;
    endButton.alpha=0;
     startButton.alpha=1;
    [UIView commitAnimations];
    isPause=false;
    [mzCostTimeLabel start];
    [[SOMotionDetector sharedInstance] startDetection];
    [[SOStepDetector sharedInstance] startDetectionWithUpdateBlock:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        
        stepCount++;
        [self setStepCount:stepCount];
    }];
}

-(void)startRunning:(id)sender{
    
    if (!isStart&&!isEnd) {//开始跑步
        
        SFCountdownView *sfCountdownView=[self countdownView];
        [sfCountdownView start];
        startButton.displayShading=NO;
        startButton.animateTap=NO;
        isStart = !isStart;
        
    }else if(!isPause&&!isEnd){//暂停跑步
        
        //暂停跑步，展开两个按钮，一个显示结束，一个显示继续
        [UIView beginAnimations:@"btnAnimation" context:nil];
        //设置动画时间为1s
        [UIView setAnimationDuration:1.0f];
        [UIView setAnimationDelegate:self];
        startButton.alpha=0;
        continueButton.alpha=1;
        endButton.alpha=1;
        continueButton.center=CGPointMake(SCREEN_WIDTH/4*3, buttonCenterY);
        endButton.center=CGPointMake(SCREEN_WIDTH/4, buttonCenterY);
        //提交动画
        [UIView commitAnimations];
        
        if([mzCostTimeLabel counting]){
            [mzCostTimeLabel pause];
        }
        
        [[SOStepDetector sharedInstance]stopDetection];
        [[SOMotionDetector sharedInstance] stopDetection];
        
        isPause=!isPause;
    }
    else if (isEnd){
        //重置
        [self reset];

    }
   
}

#pragma mark - MZTimerLabelDelegate
-(void)timerLabel:(MZTimerLabel*)timerLabel countingTo:(NSTimeInterval)time timertype:(MZTimerLabelType)timerType{
    //计算实时步频，计算方法，每秒钟计算走过的步数,因为当前方法是每秒钟触发一次，所以只需要
    //计算上一次的步数和这次的步数之差即可算出来
    int realTimeStepCount=stepCount-lastSecondStepCount;
    realTimeStepFrequenceLabel.text=[NSString stringWithFormat:@"%d",realTimeStepCount*60];
    
    
    NSLog(@"%f",time);
    
    
    //计算平均步频
    double averageStepSeq=0;
    if (time>1) {
        averageStepSeq=stepCount/(time/60);
    }
    
    
    averageStepFrequenceLabel.text=[NSString stringWithFormat:@"%.f",ceil(averageStepSeq)];
    
    //方法结束时，设置上一秒的总步数
    lastSecondStepCount=stepCount;
}

- (BOOL)prefersStatusBarHidden
{
    return NO; //返回NO表示要显示，返回YES将hiden
}

@end
