//
//  ViewController.m
//  CarSpin
//
//  Created by Moses DeJong on 11/04/15.
//

#import "ViewController.h"

#import "AVFileUtil.h"

#import "AVAssetJoinAlphaResourceLoader.h"

#import "AVApng2MvidResourceLoader.h"

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

  NSString *alphaResourceName = @"low_car_ANI_alpha_CRF_30_24BPP.m4v";
  NSString *rgbResourceName = @"low_car_ANI_rgb_CRF_30_24BPP.m4v";
  
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
  
  // This loader will join 2 H.264 videos together into a single 32BPP .mvid
  
  AVAssetJoinAlphaResourceLoader *resLoader = [AVAssetJoinAlphaResourceLoader aVAssetJoinAlphaResourceLoader];
  
  resLoader.movieRGBFilename = rgbResourceName;
  resLoader.movieAlphaFilename = alphaResourceName;
  resLoader.outPath = tmpPath;
  resLoader.alwaysGenerateAdler = TRUE;
  
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
  
  [self.view.layer addSublayer:layer];
  
  AVAnimatorLayer *animatorLayer = [AVAnimatorLayer aVAnimatorLayer:layer];
  
  self.carAnimatorLayer = animatorLayer;
  
  // Finally connect the media object to the layer so that rendering will be
  // sent to the layer.
  
  [animatorLayer attachMedia:media];
  
  media.animatorRepeatCount = INT_MAX;
  
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
  
  [self.carMedia startAnimator];
  
  return;
}

@end
