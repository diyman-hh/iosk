#import "RootViewController.h"
#import "AutomationManager.h"
#import "ScreenCapture.h"
#import "VisionHelper.h"

@interface RootViewController () <UITextFieldDelegate>
@property(nonatomic, strong) UITextField *startHourField;
@property(nonatomic, strong) UITextField *endHourField;
@property(nonatomic, strong) UITextField *minWatchField;
@property(nonatomic, strong) UITextField *maxWatchField;
@property(nonatomic, strong) UIButton *toggleButton;
@property(nonatomic, strong) UITextView *logView;
@end

@implementation RootViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.title = @"TrollTouch Config";

  [self setupUI];
  [self loadSettings];

  // Bind Logger
  __weak typeof(self) weakSelf = self;
  [AutomationManager sharedManager].logHandler = ^(NSString *log) {
    [weakSelf appendLog:log];
  };
}

- (void)setupUI {
  CGFloat y = 80;
  CGFloat w = self.view.bounds.size.width;
  CGFloat pad = 20;

  UILabel *titleLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(pad, y, w - 2 * pad, 30)];
  titleLabel.text = @"工作时间 (0-24)";
  titleLabel.font = [UIFont boldSystemFontOfSize:16];
  [self.view addSubview:titleLabel];
  y += 35;

  self.startHourField =
      [self createField:@"开始 (如 9)"
                  frame:CGRectMake(pad, y, (w - 3 * pad) / 2, 40)];
  self.endHourField =
      [self createField:@"结束 (如 23)"
                  frame:CGRectMake(pad + (w - 3 * pad) / 2 + pad, y,
                                   (w - 3 * pad) / 2, 40)];
  y += 50;

  UILabel *watchLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(pad, y, w - 2 * pad, 30)];
  watchLabel.text = @"观看时长 (秒)";
  watchLabel.font = [UIFont boldSystemFontOfSize:16];
  [self.view addSubview:watchLabel];
  y += 35;

  self.minWatchField =
      [self createField:@"最小 (3)"
                  frame:CGRectMake(pad, y, (w - 3 * pad) / 2, 40)];
  self.maxWatchField =
      [self createField:@"最大 (8)"
                  frame:CGRectMake(pad + (w - 3 * pad) / 2 + pad, y,
                                   (w - 3 * pad) / 2, 40)];
  y += 60;

  self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.toggleButton.frame = CGRectMake(pad, y, w - 2 * pad, 50);
  self.toggleButton.backgroundColor = [UIColor systemBlueColor];
  [self.toggleButton setTitle:@"开始运行 (5秒后启动)"
                     forState:UIControlStateNormal];
  [self.toggleButton setTitleColor:[UIColor whiteColor]
                          forState:UIControlStateNormal];
  self.toggleButton.layer.cornerRadius = 8;
  [self.toggleButton addTarget:self
                        action:@selector(toggleAutomation)
              forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.toggleButton];
  y += 60;

  UIButton *testFollowButton = [UIButton buttonWithType:UIButtonTypeSystem];
  testFollowButton.frame = CGRectMake(pad, y, (w - 3 * pad) / 2, 50);
  testFollowButton.backgroundColor = [UIColor systemOrangeColor];
  [testFollowButton setTitle:@"测试: 关注" forState:UIControlStateNormal];
  [testFollowButton setTitleColor:[UIColor whiteColor]
                         forState:UIControlStateNormal];
  testFollowButton.layer.cornerRadius = 8;
  [testFollowButton addTarget:self
                       action:@selector(testFollow)
             forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:testFollowButton];

  UIButton *testLikeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  testLikeButton.frame =
      CGRectMake(pad + (w - 3 * pad) / 2 + pad, y, (w - 3 * pad) / 2, 50);
  testLikeButton.backgroundColor = [UIColor systemOrangeColor];
  [testLikeButton setTitle:@"测试: 点赞" forState:UIControlStateNormal];
  [testLikeButton setTitleColor:[UIColor whiteColor]
                       forState:UIControlStateNormal];
  testLikeButton.layer.cornerRadius = 8;
  [testLikeButton addTarget:self
                     action:@selector(testLike)
           forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:testLikeButton];
  y += 60;

  UIButton *testSwipeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  testSwipeButton.frame = CGRectMake(pad, y, w - 2 * pad, 50);
  testSwipeButton.backgroundColor = [UIColor systemOrangeColor];
  [testSwipeButton setTitle:@"测试: 下一个视频 (滑动)"
                   forState:UIControlStateNormal];
  [testSwipeButton setTitleColor:[UIColor whiteColor]
                        forState:UIControlStateNormal];
  testSwipeButton.layer.cornerRadius = 8;
  [testSwipeButton addTarget:self
                      action:@selector(testSwipe)
            forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:testSwipeButton];
  y += 60;

  UIButton *visButton = [UIButton buttonWithType:UIButtonTypeSystem];
  visButton.frame = CGRectMake(pad, y, w - 2 * pad, 50);
  visButton.backgroundColor = [UIColor systemGreenColor];
  [visButton setTitle:@"可视化坐标 (保存到相册)" forState:UIControlStateNormal];
  [visButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  visButton.layer.cornerRadius = 8;
  [visButton addTarget:self
                action:@selector(visualizePositions)
      forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:visButton];
  visButton.layer.cornerRadius = 8;
  [visButton addTarget:self
                action:@selector(visualizePositions)
      forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:visButton];
  y += 60;

  UILabel *logLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(pad, y, w - 2 * pad, 20)];
  logLabel.text = @"运行日志:";
  [self.view addSubview:logLabel];
  y += 25;

  self.logView = [[UITextView alloc]
      initWithFrame:CGRectMake(pad, y, w - 2 * pad,
                               self.view.bounds.size.height - y - 30)];
  self.logView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
  self.logView.editable = NO;
  self.logView.font = [UIFont fontWithName:@"Courier" size:10];
  [self.view addSubview:self.logView];

  // Load previous logs from Public Downloads
  NSString *docPath = @"/var/mobile/Media/Downloads/TrollTouch_Logs";
  NSString *crashPath = [docPath stringByAppendingPathComponent:@"crash.log"];
  NSString *appLogPath = [docPath stringByAppendingPathComponent:@"app.log"];

  NSMutableString *history = [NSMutableString string];

  if ([[NSFileManager defaultManager] fileExistsAtPath:crashPath]) {
    // Limit crash log size reading
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:crashPath];
    unsigned long long fileSize = [file seekToEndOfFile];
    unsigned long long offset = (fileSize > 4096) ? fileSize - 4096 : 0;
    [file seekToFileOffset:offset];
    NSData *data = [file readDataToEndOfFile];
    NSString *crashLog = [[NSString alloc] initWithData:data
                                               encoding:NSUTF8StringEncoding];
    [history appendFormat:@"[CRASH LOG DETECTED]\n%@\n\n", crashLog];
  }

  // Read last 2KB of app log
  if ([[NSFileManager defaultManager] fileExistsAtPath:appLogPath]) {
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:appLogPath];
    unsigned long long fileSize = [file seekToEndOfFile];
    unsigned long long offset = (fileSize > 2048) ? fileSize - 2048 : 0;
    [file seekToFileOffset:offset];
    NSData *data = [file readDataToEndOfFile];
    NSString *recentLog = [[NSString alloc] initWithData:data
                                                encoding:NSUTF8StringEncoding];
    [history appendFormat:@"[RECENT LOGS]\n%@\n", recentLog];
  }

  if (history.length > 0) {
    _logView.text = history;
  } else {
    _logView.text =
        [NSString stringWithFormat:@"日志将保存在:\n%@\n等待输出...", docPath];
  }

  // Tap to dismiss keyboard
  UITapGestureRecognizer *tap =
      [[UITapGestureRecognizer alloc] initWithTarget:self.view
                                              action:@selector(endEditing:)];
  [self.view addGestureRecognizer:tap];
}

- (UITextField *)createField:(NSString *)place frame:(CGRect)frame {
  UITextField *tf = [[UITextField alloc] initWithFrame:frame];
  tf.placeholder = place;
  tf.borderStyle = UITextBorderStyleRoundedRect;
  tf.keyboardType = UIKeyboardTypeNumberPad;
  [self.view addSubview:tf];
  return tf;
}

- (void)toggleAutomation {
  AutomationManager *mgr = [AutomationManager sharedManager];

  if ([mgr isRunning]) {
    [mgr stopAutomation];
    [self.toggleButton setTitle:@"开始运行 (5秒后启动)"
                       forState:UIControlStateNormal];
    self.toggleButton.backgroundColor = [UIColor systemBlueColor];
  } else {
    [self saveSettings];
    [mgr startAutomation];
    [self.toggleButton setTitle:@"停止运行" forState:UIControlStateNormal];
    self.toggleButton.backgroundColor = [UIColor systemRedColor];
  }
}

- (void)testFollow {
  [self appendLog:@"[测试] 正在切换到 TikTok..."];
  [[AutomationManager sharedManager] launchTikTok];

  [self appendLog:@"[测试] 3秒后执行关注测试..."];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [[AutomationManager sharedManager] performFollow];
      });
}

- (void)testLike {
  [self appendLog:@"[测试] 正在切换到 TikTok..."];
  [[AutomationManager sharedManager] launchTikTok];

  [self appendLog:@"[测试] 3秒后执行点赞测试..."];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [[AutomationManager sharedManager] performLike];
      });
}

- (void)testSwipe {
  [self appendLog:@"[测试] 正在切换到 TikTok..."];
  [[AutomationManager sharedManager] launchTikTok];

  [self appendLog:@"[测试] 3秒后执行滑动测试..."];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [[AutomationManager sharedManager] performHumanSwipe];
      });
}

- (void)visualizePositions {
  [self appendLog:@"[*] 正在生成可视化坐标..."];
  [self appendLog:@"[*] 3秒后截图... 请立即切换到 TikTok!"];

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        UIImage *screen = captureScreen();
        if (!screen) {
          [self appendLog:@"[-] 截图失败。"];
          return;
        }

        UIImage *debugImg = drawDebugRects(screen);
        UIImageWriteToSavedPhotosAlbum(debugImg, nil, nil, nil);
        [self appendLog:@"[+] 坐标图已保存到相册! 请去相册查看。"];
      });
}

// ... saveSettings and loadSettings logic is mostly numeric, but UI labels
// update ...

- (void)saveSettings {
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  [def setInteger:[self.startHourField.text intValue] forKey:@"startHour"];
  [def setInteger:[self.endHourField.text intValue] forKey:@"endHour"];
  [def setInteger:[self.minWatchField.text intValue] forKey:@"minWatch"];
  [def setInteger:[self.maxWatchField.text intValue] forKey:@"maxWatch"];
  [def synchronize];

  TrollConfig cfg = [AutomationManager sharedManager].config;
  cfg.startHour = [self.startHourField.text intValue];
  cfg.endHour = [self.endHourField.text intValue];
  cfg.minWatchSec = [self.minWatchField.text intValue];
  cfg.maxWatchSec = [self.maxWatchField.text intValue];
  [AutomationManager sharedManager].config = cfg;
}

- (void)loadSettings {
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  if ([def objectForKey:@"startHour"] == nil) {
    self.startHourField.text = @"5";
    self.endHourField.text = @"23";
    self.minWatchField.text = @"3";
    self.maxWatchField.text = @"8";
  } else {
    self.startHourField.text = [NSString
        stringWithFormat:@"%ld", (long)[def integerForKey:@"startHour"]];
    self.endHourField.text = [NSString
        stringWithFormat:@"%ld", (long)[def integerForKey:@"endHour"]];
    self.minWatchField.text = [NSString
        stringWithFormat:@"%ld", (long)[def integerForKey:@"minWatch"]];
    self.maxWatchField.text = [NSString
        stringWithFormat:@"%ld", (long)[def integerForKey:@"maxWatch"]];
  }
}

- (void)appendLog:(NSString *)msg {
  NSString *newText =
      [NSString stringWithFormat:@"%@\n%@", self.logView.text, msg];
  if (newText.length > 5000) {
    newText = [newText substringFromIndex:newText.length - 5000];
  }
  self.logView.text = newText;
  [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length, 1)];
}

@end
