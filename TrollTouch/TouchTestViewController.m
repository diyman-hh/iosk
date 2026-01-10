#import "TouchTestViewController.h"
#import "AgentClient.h"

@interface TouchTestViewController ()
@property(nonatomic, strong) UIView *canvasView;
@property(nonatomic, strong) CAShapeLayer *pathLayer;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UITextView *logTextView;
@property(nonatomic, strong) NSMutableArray<CAShapeLayer *> *tapLayers;
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

- (void)addLog:(NSString *)message {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *timestamp =
        [NSDateFormatter localizedStringFromDate:[NSDate date]
                                       dateStyle:NSDateFormatterNoStyle
                                       timeStyle:NSDateFormatterMediumStyle];
    NSString *logEntry =
        [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    self.logTextView.text =
        [self.logTextView.text stringByAppendingString:logEntry];

    // Auto-scroll to bottom
    NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
    [self.logTextView scrollRangeToVisible:range];
  });
  NSLog(@"[TouchTest] %@", message);
}

- (void)startAutoTest {
  self.statusLabel.text = @"Testing via AgentClient...";
  [self addLog:@"========== AGENT CLIENT TEST STARTED =========="];
  [self addLog:@"📡 Connecting to TrollTouchAgent..."];

  [self clearCanvas];

  // First check if Agent is online
  [[AgentClient sharedClient] checkStatus:^(BOOL online, NSDictionary *info) {
    if (online) {
      [self addLog:[NSString stringWithFormat:@"✅ Agent is ONLINE: %@", info]];
      [self addLog:@"🚀 Starting touch injection tests..."];

      // Run test in background
      dispatch_async(
          dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self runAutoTest];
          });
    } else {
      [self addLog:@"❌ Agent is OFFLINE"];
      [self addLog:@"⚠️ Please make sure TrollTouchAgent is running!"];
      [self addLog:@"Steps:"];
      [self addLog:@"1. Open TrollTouchAgent app"];
      [self addLog:@"2. Wait for 'HTTP Server: localhost:8100' message"];
      [self addLog:@"3. Return to this app and try again"];

      dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = @"❌ Agent Offline";
      });
    }
  }];
}

- (void)runAutoTest {
  // Test 5 random swipes via AgentClient
  [self addLog:@""];
  [self addLog:@"--- Testing 5 Swipes via AgentClient ---"];

  for (int i = 0; i < 5; i++) {
    float startX = 0.2 + (arc4random() % 60) / 100.0;
    float startY = 0.2 + (arc4random() % 60) / 100.0;
    float endX = 0.2 + (arc4random() % 60) / 100.0;
    float endY = 0.2 + (arc4random() % 60) / 100.0;

    [self addLog:[NSString stringWithFormat:
                               @"👉 Swipe #%d: (%.3f, %.3f) → (%.3f, %.3f)",
                               i + 1, startX, startY, endX, endY]];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[AgentClient sharedClient]
         swipeFrom:CGPointMake(startX, startY)
                to:CGPointMake(endX, endY)
          duration:0.3
        completion:^(BOOL success, NSError *error) {
          if (success) {
            [self addLog:[NSString
                             stringWithFormat:@"✅ Swipe #%d SUCCESS", i + 1]];
          } else {
            [self addLog:[NSString
                             stringWithFormat:@"❌ Swipe #%d FAILED: %@", i + 1,
                                              error.localizedDescription]];
          }
          dispatch_semaphore_signal(semaphore);
        }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    usleep(500000); // 0.5s between swipes

    dispatch_async(dispatch_get_main_queue(), ^{
      self.statusLabel.text =
          [NSString stringWithFormat:@"Swipe Test %d/5", i + 1];
    });
  }

  // Test 5 random taps via AgentClient
  [self addLog:@""];
  [self addLog:@"--- Testing 5 Taps via AgentClient ---"];

  for (int i = 0; i < 5; i++) {
    float tapX = 0.2 + (arc4random() % 60) / 100.0;
    float tapY = 0.2 + (arc4random() % 60) / 100.0;

    [self addLog:[NSString stringWithFormat:@"👆 Tap #%d: (%.3f, %.3f)", i + 1,
                                            tapX, tapY]];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[AgentClient sharedClient]
        tapAtPoint:CGPointMake(tapX, tapY)
        completion:^(BOOL success, NSError *error) {
          if (success) {
            [self addLog:[NSString
                             stringWithFormat:@"✅ Tap #%d SUCCESS", i + 1]];
          } else {
            [self addLog:[NSString
                             stringWithFormat:@"❌ Tap #%d FAILED: %@", i + 1,
                                              error.localizedDescription]];
          }
          dispatch_semaphore_signal(semaphore);
        }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
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
