#import "ScreenCapture.h"

UIImage *captureScreen(void) {
  // Attempt 1: _UICreateScreenUIImage
  // This is a private symbol in UIKit that takes a snapshot of the main display
  UIImage *image = _UICreateScreenUIImage();

  if (image) {
    // printf("[ScreenCapture] Successfully captured screen via
    // _UICreateScreenUIImage\n");
    return image;
  }

  printf(
      "[-] _UICreateScreenUIImage returned NULL. Sandbox/Entitlement issue?\n");
  return nil;
}

void saveScreenshotToDocuments(void) {
  UIImage *img = captureScreen();
  if (!img)
    return;

  // Convert to PNG
  NSData *pngData = UIImagePNGRepresentation(img);
  if (!pngData)
    return;

  // Save to Documents/screenshot.png
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath = [documentsDirectory
      stringByAppendingPathComponent:@"debug_screenshot.png"];

  [pngData writeToFile:filePath atomically:YES];
  printf("[*] Screenshot saved to: %s\n", [filePath UTF8String]);
}
