#import "TouchTestViewController.h"
#import "AgentClient.h"

@interface TouchTestViewController ()
@property(nonatomic, strong) UIView *canvasView;
@property(nonatomic, strong) CAShapeLayer *pathLayer;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UITextView *logTextView;
@property(nonatomic, strong) NSMutableArray<CAShapeLayer *> *tapLayers;
@property(nonatomic, assign) BOOL isTesting;

- (void)addLog:(NSString *)message;
- (void)clearCanvas;
- (void)closeTest;
- (void)toggleTest:(UIButton *)sender;
- (void)startAutoTest;
@end

@implementation TouchTestViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];
  self.tapLayers = [NSMutableArray array];

  // Canvas for drawing
  self.canvasView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
                               self.view.bounds.size.height * 0.6)];
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
  self.statusLabel.text = @"Connecting to Agent...";
  [self.view addSubview:self.statusLabel];

  // Log text view
  CGFloat logY = self.canvasView.frame.size.height;
  self.logTextView = [[UITextView alloc]
      initWithFrame:CGRectMake(10, logY, self.view.bounds.size.width - 20,
                               self.view.bounds.size.height - logY - 150)];
  self.logTextView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
  self.logTextView.font = [UIFont fontWithName:@"Menlo" size:10];
  self.logTextView.editable = NO;
  self.logTextView.text = @"";
  [self.view addSubview:self.logTextView];

  // Buttons
  [self setupButtons];
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

  // Test button (Start/Stop)
  UIButton *testBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  testBtn.tag = 100; // Tag to find it later
  testBtn.frame =
      CGRectMake(self.view.bounds.size.width - buttonWidth - spacing, startY,
                 buttonWidth, buttonHeight);
  [testBtn setTitle:@"Start Random" forState:UIControlStateNormal];
  testBtn.backgroundColor = [UIColor colorWithRed:0.2
                                            green:0.6
                                             blue:1.0
                                            alpha:1.0];
  testBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
  [testBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  testBtn.layer.cornerRadius = 8;
  [testBtn addTarget:self
                action:@selector(toggleTest:)
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

- (void)toggleTest:(UIButton *)sender {
  if (self.isTesting) {
    // Stop
    self.isTesting = NO;
    [sender setTitle:@"Start Random" forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor colorWithRed:0.2
                                             green:0.6
                                              blue:1.0
                                             alpha:1.0]; // Blue
    [self addLog:@"⏹️ Random Test Stopped"];
  } else {
    // Start
    self.isTesting = YES;
    [sender setTitle:@"Stop Test" forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor colorWithRed:1.0
                                             green:0.3
                                              blue:0.3
                                             alpha:1.0]; // Red
    [self startAutoTest];
  }
}

- (void)startAutoTest {
  if (!self.isTesting)
    return;

  self.statusLabel.text = @"Connecting...";
  [self addLog:@"========== RANDOM TEST STARTED =========="];

  // Check Agent Status
  [[AgentClient sharedClient] checkStatus:^(BOOL online, NSDictionary *info) {
    if (!self.isTesting)
      return;

    if (online) {
      [self addLog:@"✅ Agent Connected"];
      [self addLog:@"🚀 Running loop (Tap/Swipe)..."];

      // Start Loop in background
      dispatch_async(
          dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self runRandomLoop];
          });
    } else {
      [self addLog:@"❌ Agent Offline!"];
      [self toggleTest:(UIButton *)[self.view viewWithTag:100]]; // Reset button
    }
  }];
}

- (void)runRandomLoop {
  int count = 0;
  while (self.isTesting) {
    count++;

    // Randomly choose Tap (70%) or Swipe (30%)
    BOOL doSwipe = (arc4random() % 100) > 70;

    // Generate coordinates within the WHITE CANVAS area (top 60%)
    // Normalized Y should be 0.1 to 0.5 to stay safely inside canvas
    float yMin = 0.1;
    float yMax = 0.5;
    float xMin = 0.1;
    float xMax = 0.9;

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    if (doSwipe) {
      float startX = xMin + (arc4random() % 100) / 100.0 * (xMax - xMin);
      float startY = yMin + (arc4random() % 100) / 100.0 * (yMax - yMin);
      float endX = xMin + (arc4random() % 100) / 100.0 * (xMax - xMin);
      float endY = yMin + (arc4random() % 100) / 100.0 * (yMax - yMin);

      dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text =
            [NSString stringWithFormat:@"#%d: Swiping...", count];
      });

      [[AgentClient sharedClient] swipeFrom:CGPointMake(startX, startY)
                                         to:CGPointMake(endX, endY)
                                   duration:0.3
                                 completion:^(BOOL success, NSError *error) {
                                   dispatch_semaphore_signal(sem);
                                 }];

    } else {
      float x = xMin + (arc4random() % 100) / 100.0 * (xMax - xMin);
      float y = yMin + (arc4random() % 100) / 100.0 * (yMax - yMin);

      dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text =
            [NSString stringWithFormat:@"#%d: Tapping...", count];
      });

      [[AgentClient sharedClient] tapAtPoint:CGPointMake(x, y)
                                  completion:^(BOOL success, NSError *error) {
                                    if (!success) {
                                      NSLog(@"Tap failed: %@", error);
                                    }
                                    dispatch_semaphore_signal(sem);
                                  }];
    }

    // Wait for command to finish
    dispatch_semaphore_wait(sem,
                            dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC));

    // Sleep random time (0.2s - 1.0s)
    useconds_t sleepTime = 200000 + (arc4random() % 800000);
    usleep(sleepTime);
  }
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
