//
//  ViewController.m
//  FFMpeg_Player
//
//  Created by apple on 16/11/30.
//  Copyright © 2016年 fht. All rights reserved.
//

#import "ViewController.h"

#import "frame.h"
#import "avformat.h"
#import "avcodec.h"
#import "avio.h"
#import "swscale.h"
#import "imgutils.h"


@interface ViewController ()

@property (weak,nonatomic) IBOutlet UIImageView *imageview;
@end

@implementation ViewController
{
    AVFormatContext *formatContext;
    AVCodecContext *pCodeContext;
    AVCodec *pCodec;
    AVFrame *pFrame;
    AVPacket packed;
    
    struct SwsContext *img_convert_ctx;
    int videoStream;
    int audioStream;
    
    CGFloat height;
    CGFloat width;
    AVFrame *outFrame;
    uint8_t *out_buffer;

}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self registerAVcodec];
    [self setupFrame];
    [self convertFrameToRGB];
    
    UIImage *image = [self imageFromAVPicture:*(outFrame) width:width height:height];
    self.imageview.image = image;
    NSLog(@"---");
}

-(UIImage *)getCurrentImage{
    if (!pFrame->data[0]) return nil;
    
    return nil;
}
-(void)convertFrameToRGB{
    
    sws_scale(img_convert_ctx, (const uint8_t *const *)pFrame->data, pFrame->linesize, 0, pCodeContext->height, outFrame->data, outFrame->linesize);
}
-(void)registerAVcodec{
    NSString *url = @"/Users/apple/Desktop/mp4/videoplayback_4_start=44000.mp4";
    
    formatContext = NULL;
    pCodeContext = NULL;
    pCodec = NULL;
    pFrame = NULL;
    
    
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
    pCodeContext = avcodec_alloc_context3(NULL);
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
    height = pCodeContext->height;
    width = pCodeContext->width;
    
    [self setupScaler];
}

-(BOOL)setupFrame{
    int frameFinished = 0;
    while (!frameFinished && av_read_frame(formatContext, &packed)>=0) {
        if (packed.stream_index == videoStream) {
            int ret = avcodec_send_packet(pCodeContext, &packed);
            if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF)
                return NO;
            
            ret = avcodec_receive_frame(pCodeContext, pFrame);
            if (ret < 0 && ret != AVERROR_EOF)
                return NO;
        }
        if (packed.stream_index == audioStream) {
            NSLog(@"--audiostream");
        }
    }
    return YES;
}

- (void)setupScaler
{
    // Release old picture and scaler
    av_free(outFrame);
    sws_freeContext(img_convert_ctx);
    
    // Allocate RGB picture
    outFrame = av_frame_alloc();
    out_buffer=(unsigned char *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_RGB24,  pCodeContext->width, pCodeContext->height,1));
    
    av_image_fill_arrays(outFrame->data, outFrame->linesize,out_buffer,
                         AV_PIX_FMT_RGB24,pCodeContext->width, pCodeContext->height,1);
    
    // Setup scaler
    static int sws_flags =  SWS_FAST_BILINEAR;
    img_convert_ctx = sws_getContext(pCodeContext->width,
                                     pCodeContext->height,
                                     pCodeContext->pix_fmt,
                                     width,
                                     height,
                                     AV_PIX_FMT_RGB24,
                                     sws_flags, NULL, NULL, NULL);
    
}

- (UIImage *)imageFromAVPicture:(AVFrame)pict width:(int)width1 height:(int)height1
{
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width1,
                                       height1,
                                       8,
                                       24,
                                       pict.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}
@end
