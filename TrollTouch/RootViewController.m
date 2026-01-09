//
//  RootViewController.m
//  TrollTouch (XCTest + TrollStore Perfect Solution)
//

#import "RootViewController.h"
#import "ScheduleManager.h"
#import "XCTestRunner.h"

@implementation RootViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor colorWithRed:0.95
                                              green:0.95
                                               blue:0.97
                                              alpha:1.0];

  CGFloat w = self.view.bounds.size.width;
  CGFloat y = 60;

  // Title
  UILabel *titleLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(20, y, w - 40, 50)];
  titleLabel.text = @"🤖 TikTok 自动化";
  titleLabel.font = [UIFont boldSystemFontOfSize:32];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:titleLabel];
  y += 60;

  // Subtitle
  UILabel *subtitle =
      [[UILabel alloc] initWithFrame:CGRectMake(20, y, w - 40, 25)];
  subtitle.text = @"TrollStore + XCTest 完美方案";
  subtitle.font = [UIFont systemFontOfSize:14];
  subtitle.textColor = [UIColor grayColor];
  subtitle.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:subtitle];
  y += 45;

  // === 定时设置区域 ===
  UIView *scheduleSection =
      [[UIView alloc] initWithFrame:CGRectMake(20, y, w - 40, 180)];
  scheduleSection.backgroundColor = [UIColor whiteColor];
  scheduleSection.layer.cornerRadius = 12;
  scheduleSection.layer.shadowColor = [UIColor blackColor].CGColor;
  scheduleSection.layer.shadowOffset = CGSizeMake(0, 2);
  scheduleSection.layer.shadowRadius = 4;
  scheduleSection.layer.shadowOpacity = 0.1;
  [self.view addSubview:scheduleSection];

  // 定时开关
  UILabel *scheduleLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 200, 30)];
  scheduleLabel.text = @"启用定时任务";
  scheduleLabel.font = [UIFont boldSystemFontOfSize:16];
  [scheduleSection addSubview:scheduleLabel];

  UISwitch *scheduleSwitch =
      [[UISwitch alloc] initWithFrame:CGRectMake(w - 90, 15, 51, 31)];
  scheduleSwitch.on = [ScheduleManager sharedManager].isEnabled;
  [scheduleSwitch addTarget:self
                     action:@selector(scheduleToggled:)
           forControlEvents:UIControlEventValueChanged];
  [scheduleSection addSubview:scheduleSwitch];

  // 开始时间
  UILabel *startLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(15, 60, 100, 30)];
  startLabel.text = @"开始时间:";
  startLabel.font = [UIFont systemFontOfSize:14];
  [scheduleSection addSubview:startLabel];

  UITextField *startField =
      [[UITextField alloc] initWithFrame:CGRectMake(120, 60, 80, 30)];
  startField.text = [NSString
      stringWithFormat:@"%ld:00",
                       (long)[ScheduleManager sharedManager].startHour];
  startField.borderStyle = UITextBorderStyleRoundedRect;
  startField.textAlignment = NSTextAlignmentCenter;
  startField.tag = 100;
  [scheduleSection addSubview:startField];

  // 结束时间
  UILabel *endLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(15, 105, 100, 30)];
  endLabel.text = @"结束时间:";
  endLabel.font = [UIFont systemFontOfSize:14];
  [scheduleSection addSubview:endLabel];

  UITextField *endField =
      [[UITextField alloc] initWithFrame:CGRectMake(120, 105, 80, 30)];
  endField.text =
      [NSString stringWithFormat:@"%ld:00",
                                 (long)[ScheduleManager sharedManager].endHour];
  endField.borderStyle = UITextBorderStyleRoundedRect;
  endField.textAlignment = NSTextAlignmentCenter;
  endField.tag = 101;
  [scheduleSection addSubview:endField];

  // 保存按钮
  UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
  saveButton.frame = CGRectMake(15, 145, w - 70, 25);
  [saveButton setTitle:@"保存设置" forState:UIControlStateNormal];
  saveButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [saveButton addTarget:self
                 action:@selector(saveSchedule)
       forControlEvents:UIControlEventTouchUpInside];
  [scheduleSection addSubview:saveButton];

  y += 200;

  // === 手动控制区域 ===
  // Start button
  UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
  startButton.frame = CGRectMake(40, y, w - 80, 60);
  [startButton setTitle:@"🚀 立即启动" forState:UIControlStateNormal];
  startButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
  startButton.backgroundColor = [UIColor colorWithRed:0.2
                                                green:0.8
                                                 blue:0.4
                                                alpha:1.0];
  [startButton setTitleColor:[UIColor whiteColor]
                    forState:UIControlStateNormal];
  startButton.layer.cornerRadius = 12;
  [startButton addTarget:self
                  action:@selector(startNow)
        forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:startButton];
  y += 70;

  // Stop button
  UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
  stopButton.frame = CGRectMake(40, y, w - 80, 50);
  [stopButton setTitle:@"⏹ 停止" forState:UIControlStateNormal];
  stopButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
  stopButton.backgroundColor = [UIColor colorWithRed:0.9
                                               green:0.3
                                                blue:0.3
                                               alpha:1.0];
  [stopButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  stopButton.layer.cornerRadius = 12;
  [stopButton addTarget:self
                 action:@selector(stopNow)
       forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:stopButton];
  y += 70;

  // === 说明区域 ===
  // === 日志显示区域 (替代说明文字) ===
  UILabel *logLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(20, y, w - 40, 20)];
  logLabel.text = @"📝 运行日志:";
  logLabel.font = [UIFont boldSystemFontOfSize:14];
  [self.view addSubview:logLabel];
  y += 25;

  self.logTextView =
      [[UITextView alloc] initWithFrame:CGRectMake(20, y, w - 40, 160)];
  self.logTextView.editable = NO;
  self.logTextView.font = [UIFont fontWithName:@"Menlo-Regular"
                                          size:10]; // Monospace font
  self.logTextView.backgroundColor = [UIColor blackColor];
  self.logTextView.textColor = [UIColor greenColor];
  self.logTextView.layer.cornerRadius = 8;
  self.logTextView.text = @"[System] Ready. Waiting for commands...\n";
  [self.view addSubview:self.logTextView];

  // Expose to AutomationManager via notification or singleton (simplified here)
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appendLog:)
                                               name:@"LogNotification"
                                             object:nil];
}

- (void)scheduleToggled:(UISwitch *)sender {
  [ScheduleManager sharedManager].isEnabled = sender.on;

  if (sender.on) {
    [[ScheduleManager sharedManager] startSchedule];
    [self showToast:@"✅ 定时任务已启用"];
  } else {
    [[ScheduleManager sharedManager] stopSchedule];
    [self showToast:@"⏹ 定时任务已禁用"];
  }
}

- (void)saveSchedule {
  UITextField *startField = (UITextField *)[self.view viewWithTag:100];
  UITextField *endField = (UITextField *)[self.view viewWithTag:101];

  // Parse hours from text fields
  NSInteger startHour = [startField.text integerValue];
  NSInteger endHour = [endField.text integerValue];

  if (startHour < 0 || startHour > 23 || endHour < 0 || endHour > 23) {
    [self showAlert:@"错误" message:@"请输入有效的小时数（0-23）"];
    return;
  }

  [ScheduleManager sharedManager].startHour = startHour;
  [ScheduleManager sharedManager].endHour = endHour;

  [self showToast:@"✅ 设置已保存"];

  // Restart schedule if enabled
  if ([ScheduleManager sharedManager].isEnabled) {
    [[ScheduleManager sharedManager] stopSchedule];
    [[ScheduleManager sharedManager] startSchedule];
  }
}

- (void)startNow {
  if ([[AutomationManager sharedManager] isRunning]) {
    [self showAlert:@"提示" message:@"自动化已在运行中"];
    return;
  }

  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"🚀 启动自动化"
                       message:@"即将启动 TikTok 自动化\n\n使用 Private API "
                               @"与 GSEvent (TrollStore) 进行控制"
                preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction actionWithTitle:@"开始"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            [[AutomationManager sharedManager]
                                                startAutomation];
                                            [self showToast:@"✅ 自动化已启动"];
                                          }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)stopNow {
  [[AutomationManager sharedManager] stopAutomation];
  [self showToast:@"⏹ 自动化已停止"];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)message {
  UILabel *toast = [[UILabel alloc]
      initWithFrame:CGRectMake(40, self.view.bounds.size.height - 120,
                               self.view.bounds.size.width - 80, 50)];
  toast.text = message;
  toast.textAlignment = NSTextAlignmentCenter;
  toast.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.9];
  toast.textColor = [UIColor whiteColor];
  toast.font = [UIFont boldSystemFontOfSize:16];
  toast.layer.cornerRadius = 12;
  toast.clipsToBounds = YES;
  toast.alpha = 0;
  [self.view addSubview:toast];

  [UIView animateWithDuration:0.3
      animations:^{
        toast.alpha = 1;
      }
      completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3
            delay:2.0
            options:0
            animations:^{
              toast.alpha = 0;
            }
            completion:^(BOOL finished) {
              [toast removeFromSuperview];
            }];
      }];
}

- (void)appendLog:(NSNotification *)note {
  NSString *msg = note.object;
  dispatch_async(dispatch_get_main_queue(), ^{
    self.logTextView.text =
        [self.logTextView.text stringByAppendingFormat:@"%@\n", msg];
    if (self.logTextView.text.length > 10000) { // Limit log size
      self.logTextView.text = [self.logTextView.text
          substringFromIndex:self.logTextView.text.length - 10000];
    }
    [self.logTextView
        scrollRangeToVisible:NSMakeRange(self.logTextView.text.length, 1)];
  });
}

@end
