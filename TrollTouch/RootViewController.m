#import "RootViewController.h"
#import "AutomationManager.h"

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
  titleLabel.text = @"Working Hours (0-24)";
  titleLabel.font = [UIFont boldSystemFontOfSize:16];
  [self.view addSubview:titleLabel];
  y += 35;

  self.startHourField =
      [self createField:@"Start (e.g. 9)"
                  frame:CGRectMake(pad, y, (w - 3 * pad) / 2, 40)];
  self.endHourField =
      [self createField:@"End (e.g. 23)"
                  frame:CGRectMake(pad + (w - 3 * pad) / 2 + pad, y,
                                   (w - 3 * pad) / 2, 40)];
  y += 50;

  UILabel *watchLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(pad, y, w - 2 * pad, 30)];
  watchLabel.text = @"Watch Duration (Secs)";
  watchLabel.font = [UIFont boldSystemFontOfSize:16];
  [self.view addSubview:watchLabel];
  y += 35;

  self.minWatchField =
      [self createField:@"Min (3)"
                  frame:CGRectMake(pad, y, (w - 3 * pad) / 2, 40)];
  self.maxWatchField =
      [self createField:@"Max (8)"
                  frame:CGRectMake(pad + (w - 3 * pad) / 2 + pad, y,
                                   (w - 3 * pad) / 2, 40)];
  y += 60;

  self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.toggleButton.frame = CGRectMake(pad, y, w - 2 * pad, 50);
  self.toggleButton.backgroundColor = [UIColor systemBlueColor];
  [self.toggleButton setTitle:@"START AUTOMATION"
                     forState:UIControlStateNormal];
  [self.toggleButton setTitleColor:[UIColor whiteColor]
                          forState:UIControlStateNormal];
  self.toggleButton.layer.cornerRadius = 8;
  [self.toggleButton addTarget:self
                        action:@selector(toggleAutomation)
              forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.toggleButton];
  y += 60;

  UILabel *logLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(pad, y, w - 2 * pad, 20)];
  logLabel.text = @"Logs:";
  [self.view addSubview:logLabel];
  y += 25;

  self.logView = [[UITextView alloc]
      initWithFrame:CGRectMake(pad, y, w - 2 * pad,
                               self.view.bounds.size.height - y - 30)];
  self.logView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
  self.logView.editable = NO;
  self.logView.font = [UIFont fontWithName:@"Courier" size:10];
  [self.view addSubview:self.logView];

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
    [self.toggleButton setTitle:@"START AUTOMATION"
                       forState:UIControlStateNormal];
    self.toggleButton.backgroundColor = [UIColor systemBlueColor];
  } else {
    [self saveSettings];
    [mgr startAutomation];
    [self.toggleButton setTitle:@"STOP AUTOMATION"
                       forState:UIControlStateNormal];
    self.toggleButton.backgroundColor = [UIColor systemRedColor];
  }
}

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
  // Defaults
  if ([def objectForKey:@"startHour"] == nil) {
    self.startHourField.text = @"9";
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
