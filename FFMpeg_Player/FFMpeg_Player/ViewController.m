//
//  ViewController.m
//  FFMpeg_Player
//
//  Created by apple on 16/11/30.
//  Copyright © 2016年 fht. All rights reserved.
//

#import "ViewController.h"
//#import "avcodec.h"
//#import "avdevice.h"
//#import "avfilter.h"
//#import "avformat.h"
//#import "avutil.h"
//#import "swscale.h"
//#import "dict.h"
#import "frame.h"
#import "avformat.h"
#import "avcodec.h"
#import "avio.h"
#import "swscale.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self registerAVcodec];
}


-(void)registerAVcodec{
    NSString *url = @"/Users/apple/Desktop/mp4/videoplayback_4_start=44000.mp4";
    
    AVFormatContext *formatContext;
    AVCodecContext *pCodeContext;
    AVCodec *pCodec;
    AVFrame *pFrame;
    int videoStream;
    int audioStream;
    
    av_register_all();
    avcodec_register_all();
    avformat_network_init();
    AVDictionary *opts = 0;
    if (avformat_open_input(&formatContext, [url UTF8String], NULL, &opts) !=0) {
        NSLog(@"open file error");
        return;
    }
    if (avformat_find_stream_info(formatContext, NULL) <0) {
        NSLog(@"cant find stream");
        return;
    }
    videoStream = -1;
    audioStream = -1;
    
    for (int i = 0; i<formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type ==AVMEDIA_TYPE_VIDEO) {
            videoStream = i;
            NSLog(@"find video stream");
        }
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStream = i;
            NSLog(@"find audio stream");
        }
    }
    if (audioStream == -1 &&videoStream == -1) {
        NSLog(@"not find video and audio stream");
        return;
    }
    avcodec_parameters_to_context(pCodeContext, formatContext->streams[videoStream]->codecpar);
    
    pCodec = avcodec_find_decoder(formatContext->streams[videoStream]->codecpar->codec_id);
    if (pCodec == NULL) {
        NSLog(@"unsupport codec");
        return;
    }
    if (avcodec_open2(pCodeContext, pCodec, NULL) < 0) {
        NSLog(@"avcodec open error");
        return;
    }
    if (audioStream > -1) {
        NSLog(@"--setup audio");
    }
    pFrame = av_frame_alloc();
    NSLog(@"width:%i,height:%i",pCodeContext->width,pCodeContext->height);
//    pCodec = formatContext->streams[videoStream]->codecpar->codec_id;
//    AVCodec *

}


@end
