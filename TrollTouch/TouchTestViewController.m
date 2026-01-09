#import "TouchTestViewController.h"
#import "AutomationClient.h"

@interface TouchTestViewController ()
@property(nonatomic, strong) UIView *canvasView;
@property(nonatomic, strong) CAShapeLayer *pathLayer;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) NSMutableArray<CAShapeLayer *> *tapLayers;
@end

@implementation TouchTestViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];
  self.tapLayers = [NSMutableArray array];

  // Canvas for drawing
  self.canvasView = [[UIView alloc] initWithFrame:self.view.bounds];
  self.canvasView.backgroundColor = [UIColor whiteColor];
  self.canvasView.userInteractionEnabled = YES;
  [self.view addSubview:self.canvasView];

  // Path layer for swipe trails
  self.pathLayer = [CAShapeLayer layer];
  self.pathLayer.strokeColor = [UIColor blackColor].CGColor;
  self.pathLayer.fillColor = nil;
  self.pathLayer.lineWidth = 3.0;
  self.pathLayer.lineCap = kCALineCapRound;
  [self.canvasView.layer addSublayer:self.pathLayer];

  // Status label
  self.statusLabel = [[UILabel alloc]
      initWithFrame:CGRectMake(0, 40, self.view.bounds.size.width, 40)];
  self.statusLabel.textAlignment = NSTextAlignmentCenter;
  self.statusLabel.font = [UIFont boldSystemFontOfSize:16];
  self.statusLabel.textColor = [UIColor blueColor];
  self.statusLabel.text = @"Ready for WebDriverAgent Test";
  [self.view addSubview:self.statusLabel];

  // Buttons
  [self setupButtons];

  // Check server status
  [[AutomationClient sharedClient] checkServerStatus:^(BOOL available) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (available) {
        self.statusLabel.text = @"✅ Server Ready";
        NSLog(@"[TouchTest] ✅ AutomationServer is available");
      } else {
        self.statusLabel.text = @"⚠️ Server Not Available";
        NSLog(@"[TouchTest] ⚠️ AutomationServer not available");
      }
    });
  }];
}

- (void)setupButtons {
  CGFloat buttonWidth = 120;
  CGFloat buttonHeight = 50;
  CGFloat spacing = 20;
  CGFloat startY = self.view.bounds.size.height - 180;

  // Clear button
  UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  clearBtn.frame = CGRectMake(spacing, startY, buttonWidth, buttonHeight);
  [clearBtn setTitle:@"Clear" forState:UIControlStateNormal];
  clearBtn.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
  clearBtn.layer.cornerRadius = 8;
  [clearBtn addTarget:self
                action:@selector(clearCanvas)
      forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:clearBtn];

  // Test button
  UIButton *testBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  testBtn.frame =
      CGRectMake(self.view.bounds.size.width - buttonWidth - spacing, startY,
                 buttonWidth, buttonHeight);
  [testBtn setTitle:@"Start Test" forState:UIControlStateNormal];
  testBtn.backgroundColor = [UIColor colorWithRed:0.2
                                            green:0.6
                                             blue:1.0
                                            alpha:1.0];
  testBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
  [testBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  testBtn.layer.cornerRadius = 8;
  [testBtn addTarget:self
                action:@selector(startAutoTest)
      forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:testBtn];

  // Close button
  UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  closeBtn.frame =
      CGRectMake((self.view.bounds.size.width - buttonWidth) / 2,
                 startY + buttonHeight + spacing, buttonWidth, buttonHeight);
  [closeBtn setTitle:@"Close" forState:UIControlStateNormal];
  closeBtn.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
  closeBtn.layer.cornerRadius = 8;
  [closeBtn addTarget:self
                action:@selector(closeTest)
      forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:closeBtn];
}

- (void)clearCanvas {
  self.pathLayer.path = nil;
  for (CAShapeLayer *layer in self.tapLayers) {
    [layer removeFromSuperlayer];
  }
  [self.tapLayers removeAllObjects];
  self.statusLabel.text = @"Canvas Cleared";
  NSLog(@"[TouchTest] Canvas cleared");
}

- (void)closeTest {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)startAutoTest {
  self.statusLabel.text = @"Testing via WebDriverAgent...";
  NSLog(@"[TouchTest] ========== WEBDRIVERAGENT TEST STARTED ==========");

  [self clearCanvas];

  // Run test in background
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                 ^{
                   [self runAutoTest];
                 });
}

- (void)runAutoTest {
  // Test 5 random swipes via AutomationClient
  NSLog(@"[TouchTest] --- Testing 5 Swipes via AutomationClient ---");
  for (int i = 0; i < 5; i++) {
    float startX = 0.2 + (arc4random() % 60) / 100.0;
    float startY = 0.2 + (arc4random() % 60) / 100.0;
    float endX = 0.2 + (arc4random() % 60) / 100.0;
    float endY = 0.2 + (arc4random() % 60) / 100.0;

    NSLog(@"[TouchTest] Swipe #%d: (%.3f, %.3f) -> (%.3f, %.3f)", i + 1, startX,
          startY, endX, endY);

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    [[AutomationClient sharedClient]
         swipeFrom:CGPointMake(startX, startY)
                to:CGPointMake(endX, endY)
          duration:0.3
        completion:^(BOOL success, NSError *error) {
          if (success) {
            NSLog(@"[TouchTest] ✅ Swipe #%d succeeded", i + 1);
          } else {
            NSLog(@"[TouchTest] ❌ Swipe #%d failed: %@", i + 1,
                  error.localizedDescription);
          }
          dispatch_semaphore_signal(sem);
        }];

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    usleep(500000); // 0.5s between swipes

    dispatch_async(dispatch_get_main_queue(), ^{
      self.statusLabel.text =
          [NSString stringWithFormat:@"Swipe Test %d/5", i + 1];
    });
  }

  // Test 5 random taps via AutomationClient
  NSLog(@"[TouchTest] --- Testing 5 Taps via AutomationClient ---");
  for (int i = 0; i < 5; i++) {
    float tapX = 0.2 + (arc4random() % 60) / 100.0;
    float tapY = 0.2 + (arc4random() % 60) / 100.0;

    NSLog(@"[TouchTest] Tap #%d: (%.3f, %.3f)", i + 1, tapX, tapY);

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    [[AutomationClient sharedClient]
        tapAtPoint:CGPointMake(tapX, tapY)
        completion:^(BOOL success, NSError *error) {
          if (success) {
            NSLog(@"[TouchTest] ✅ Tap #%d succeeded", i + 1);
          } else {
            NSLog(@"[TouchTest] ❌ Tap #%d failed: %@", i + 1,
                  error.localizedDescription);
          }
          dispatch_semaphore_signal(sem);
        }];

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    usleep(300000); // 0.3s between taps

    dispatch_async(dispatch_get_main_queue(), ^{
      self.statusLabel.text =
          [NSString stringWithFormat:@"Tap Test %d/5", i + 1];
    });
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    self.statusLabel.text = @"Test Completed! Check logs";
    NSLog(@"[TouchTest] ========== WEBDRIVERAGENT TEST COMPLETED ==========");
  });
}

#pragma mark - Touch Event Handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self.canvasView];

  NSLog(@"[TouchTest] 🔴 Real Touch BEGIN at (%.1f, %.1f)", location.x,
        location.y);

  // Draw red dot
  [self drawTapAtPoint:location];

  // Start path
  UIBezierPath *path = [UIBezierPath bezierPath];
  [path moveToPoint:location];
  self.pathLayer.path = path.CGPath;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self.canvasView];

  NSLog(@"[TouchTest] 🔵 Real Touch MOVE to (%.1f, %.1f)", location.x,
        location.y);

  // Extend path
  UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:self.pathLayer.path];
  [path addLineToPoint:location];
  self.pathLayer.path = path.CGPath;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self.canvasView];

  NSLog(@"[TouchTest] 🟢 Real Touch END at (%.1f, %.1f)", location.x,
        location.y);
}

- (void)drawTapAtPoint:(CGPoint)point {
  CAShapeLayer *tapLayer = [CAShapeLayer layer];
  tapLayer.path =
      [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - 10,
                                                        point.y - 10, 20, 20)]
          .CGPath;
  tapLayer.fillColor = [UIColor redColor].CGColor;
  tapLayer.opacity = 0.7;
  [self.canvasView.layer addSublayer:tapLayer];
  [self.tapLayers addObject:tapLayer];
}

@end
