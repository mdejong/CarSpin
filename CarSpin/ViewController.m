//
//  ViewController.m
//  CarSpin
//
//  Created by Moses DeJong on 11/04/15.
//

#import "ViewController.h"

#import "AVFileUtil.h"

#import "AVAssetMixAlphaResourceLoader.h"

#import "AVAnimatorMedia.h"

#import "AVAnimatorLayer.h"

#import "AVMvidFrameDecoder.h"

#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

// Explosion

@property (nonatomic, retain) AVAnimatorMedia *carMedia;

@property (nonatomic, retain) AVAnimatorLayer *carAnimatorLayer;

@end

@implementation ViewController

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Prepare media player for Explosion video as assign to self.expMedia

- (void) prepareCarMedia
{
  // Create resource loader that will combine RGB and Alpha values back
  // into one Maxvid file.

  NSString *mixResourceName = @"low_car_ANI_mix_30_main.m4v";
  
  // Output filename
  
  NSString *tmpFilename;
  NSString *tmpPath;
  tmpFilename = @"Car.mvid";
  tmpPath = [AVFileUtil getTmpDirPath:tmpFilename];
  
  // Set to TRUE to always decode from H.264
  
  BOOL alwaysDecode = FALSE;
  
  if (alwaysDecode && [AVFileUtil fileExists:tmpPath]) {
    BOOL worked = [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    NSAssert(worked, @"could not remove file %@", tmpPath);
  }
  
  // Loader that reads RGB and Alpha frames and combines to .mvid
  
  AVAssetMixAlphaResourceLoader *resLoader = [AVAssetMixAlphaResourceLoader aVAssetMixAlphaResourceLoader];
  resLoader.movieFilename = mixResourceName;
  resLoader.outPath = tmpPath;
  
  //resLoader.alwaysGenerateAdler = TRUE;
  
  AVAnimatorMedia *media = [AVAnimatorMedia aVAnimatorMedia];
  media.resourceLoader = resLoader;
  
  self.carMedia = media;
  
  // Frame decoder will read from generated .mvid file
  
  AVMvidFrameDecoder *aVMvidFrameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
  media.frameDecoder = aVMvidFrameDecoder;
  
  // Create layer that video data will be directed into
  
  CGRect carFrame = self.view.bounds;
  
  CALayer *layer = [CALayer layer];
  layer.frame = carFrame;
  
  if (FALSE) {
    layer.backgroundColor = [UIColor orangeColor].CGColor;
  }
  
  if (TRUE) {
    layer.backgroundColor = [UIColor greenColor].CGColor;
  }
  
  [self.view.layer addSublayer:layer];
  
  AVAnimatorLayer *animatorLayer = [AVAnimatorLayer aVAnimatorLayer:layer];
  
  self.carAnimatorLayer = animatorLayer;
  
  // Finally connect the media object to the layer so that rendering will be
  // sent to the layer.
  
  [animatorLayer attachMedia:media];
  
  media.animatorRepeatCount = INT_MAX;
  
  media.animatorFrameDuration = 1.0 / 30;
  
  [media prepareToAnimate];
  
  return;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  [self prepareCarMedia];
  
  // Setup animator ready callback, will be invoked after media is done loading
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(animatorPreparedNotification:)
                                               name:AVAnimatorPreparedToAnimateNotification
                                             object:self.carMedia];
  return;
}

// Invoked once a specific media object is ready to animate.

- (void)animatorPreparedNotification:(NSNotification*)notification {
  AVAnimatorMedia *media = notification.object;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:AVAnimatorPreparedToAnimateNotification
                                                object:media];
  
  AVMvidFrameDecoder *decoder = (AVMvidFrameDecoder*) media.frameDecoder;
  NSString *file = [decoder.filePath lastPathComponent];
  NSLog( @"animatorPreparedNotification %@", file);
  
  // Size of movie is available now
  
  CGSize videoSize = CGSizeMake(self.carMedia.frameDecoder.width, self.carMedia.frameDecoder.height);
  
  CGRect videoFrame = CGRectMake(0, 0, 0, 0);
  
  videoFrame.size = videoSize;
  
  CALayer *layer = self.carAnimatorLayer.layer;
  
  layer.frame = videoFrame;
  
  // Center in view
  
  layer.anchorPoint = CGPointMake(0.5, 0.5);
  
  layer.position = (CGPoint){CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds)};
  
  [self.carMedia startAnimator];
  
  return;
}

@end
