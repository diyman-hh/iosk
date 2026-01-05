#import <UIKit/UIKit.h>

// Private API from UIKit
// This function captures the entire screen buffer
UIImage *_UICreateScreenUIImage(void);

// Public wrapper
UIImage *captureScreen(void);
void saveScreenshotToDocuments(void);
