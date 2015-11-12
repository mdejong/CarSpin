//
//  ViewController.m
//  CarSpin
//
//  Created by Moses DeJong on 11/04/15.
//

#import "ViewController.h"

#import "AVFileUtil.h"

#import "AVAnimatorView.h"

#import "AVAnimatorMedia.h"

#import "AVAssetMixAlphaResourceLoader.h"

#import "AVMvidFrameDecoder.h"

#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

// Aspect fit view that will contain the rotating Car. This view must maintain
// the aspect ratio so that the car will not stretch as it rotates around.

@property (nonatomic, retain) IBOutlet AVAnimatorView *carView;

// Media handle to decoded (loopable) file on disk

@property (nonatomic, retain) AVAnimatorMedia *carMedia;

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
  
  NSLog(@"decoding mvid %@", resLoader.outPath);
  
  AVAnimatorMedia *media = [AVAnimatorMedia aVAnimatorMedia];
  media.resourceLoader = resLoader;
  
  self.carMedia = media;
  
  // Frame decoder will read from generated .mvid file
  
  AVMvidFrameDecoder *aVMvidFrameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
  media.frameDecoder = aVMvidFrameDecoder;
  
  // Media will direct video data into self.carLayer
  
  [self.carView attachMedia:media];
  
  if (FALSE) {
//    self.carView.backgroundColor = [UIColor greenColor];
    
    self.carView.backgroundColor = [UIColor whiteColor];
  }
  
  media.animatorRepeatCount = INT_MAX;
  
  media.animatorFrameDuration = 1.0 / 30;
  
  [media prepareToAnimate];
  
  return;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor redColor];
  
  NSAssert(self.carView, @"carView");
  
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
  
  // Size of movie is available now
  
  CGSize videoSize = CGSizeMake(self.carMedia.frameDecoder.width, self.carMedia.frameDecoder.height);
  
  NSLog(@"animatorPreparedNotification %@ : videoSize %d x %d", file, (int)videoSize.width, (int)videoSize.height);
  
  NSLog(@"self.carView : %d x %d", (int)self.carView.frame.size.width, (int)self.carView.frame.size.height);
  
  [self.carMedia startAnimator];
  
  return;
}

@end
