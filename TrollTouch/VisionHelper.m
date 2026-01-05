#import "VisionHelper.h"

BOOL isPixelColor(UIImage *image, float x, float y, float r, float g, float b) {
  if (!image)
    return NO;

  CGImageRef cgImage = [image CGImage];
  size_t width = CGImageGetWidth(cgImage);
  size_t height = CGImageGetHeight(cgImage);

  int pixelX = (int)(x * width);
  int pixelY = (int)(y * height);

  // Bounds check
  if (pixelX < 0 || pixelX >= width || pixelY < 0 || pixelY >= height)
    return NO;

  CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
  const UInt8 *data = CFDataGetBytePtr(pixelData);

  size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
  size_t bytesPerPixel = CGImageGetBitsPerPixel(cgImage) / 8;
  int pixelInfo = (int)(pixelY * bytesPerRow + pixelX * bytesPerPixel);

  // Check length
  if (pixelInfo + 2 >= CFDataGetLength(pixelData)) {
    CFRelease(pixelData);
    return NO;
  }

  UInt8 red = data[pixelInfo];
  UInt8 green = data[pixelInfo + 1];
  UInt8 blue = data[pixelInfo + 2];
  CFRelease(pixelData);

  // Normalize to 0-1
  float nr = red / 255.0f;
  float ng = green / 255.0f;
  float nb = blue / 255.0f;

  // Tolerance 0.1
  float tol = 0.15;

  BOOL match = (fabs(nr - r) < tol && fabs(ng - g) < tol && fabs(nb - b) < tol);
  return match;
}

BOOL isVideoFeed(UIImage *image) {
  // Check bottom bar area (approx 0.5, 0.95). If it's dark/black, likely video
  // feed. If white, likely execution or profile.
  return isPixelColor(image, 0.5, 0.95, 0.0, 0.0, 0.0);
}

void recognizeText(UIImage *image, void (^completion)(NSString *result)) {
  if (!image) {
    completion(nil);
    return;
  }

  CGImageRef cgImage = [image CGImage];

  VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc]
      initWithCompletionHandler:^(VNRequest *request, NSError *error) {
        if (error) {
          printf("[-] OCR Error: %s\n",
                 [[error localizedDescription] UTF8String]);
          completion(nil);
          return;
        }

        NSMutableString *fullText = [NSMutableString string];
        for (VNRecognizedTextObservation *observation in request.results) {
          VNRecognizedText *candidate =
              [observation topCandidates:1].firstObject;
          if (candidate) {
            [fullText appendFormat:@"%@\n", candidate.string];
          }
        }
        completion(fullText);
      }];

  request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
  request.recognitionLanguages =
      @[ @"en-US", @"zh-Hans" ]; // Support English and Chinese

  VNImageRequestHandler *handler =
      [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];

  NSError *handlerError = nil;
  [handler performRequests:@[ request ] error:&handlerError];
  if (handlerError) {
    printf("[-] Vision Handler Error: %s\n",
           [[handlerError localizedDescription] UTF8String]);
    completion(nil);
  }
}

// Draw Debug Circles
UIImage *drawDebugRects(UIImage *original) {
  UIGraphicsBeginImageContextWithOptions(original.size, NO, 0);
  [original drawAtPoint:CGPointZero];

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetLineWidth(context, 5.0);
  CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);

  float w = original.size.width;
  float h = original.size.height;

  // Coordinates to Visualize
  // Like (0.94, 0.50)
  // Follow (0.94, 0.35)
  // Plus (0.50, 0.93)
  // Upload (0.85, 0.85)
  // Post (0.85, 0.93)

  struct Point {
    float x;
    float y;
    const char *name;
  };
  struct Point points[] = {{0.93, 0.50, "Like"},      {0.93, 0.36, "Follow"},
                           {0.50, 0.93, "Plus(+)"},   {0.85, 0.85, "Upload"},
                           {0.85, 0.93, "Post/Next"}, {0.16, 0.20, "Video1"},
                           {0.08, 0.93, "Home"}};

  for (int i = 0; i < 7; i++) {
    float cx = points[i].x * w;
    float cy = points[i].y * h;
    CGRect rect = CGRectMake(cx - 20, cy - 20, 40, 40);

    CGContextAddEllipseInRect(context, rect);
    CGContextStrokePath(context);

    // Draw Text
    NSString *label = [NSString stringWithUTF8String:points[i].name];
    NSDictionary *attrs = @{
      NSFontAttributeName : [UIFont boldSystemFontOfSize:24],
      NSForegroundColorAttributeName : [UIColor greenColor]
    };
    [label drawAtPoint:CGPointMake(cx - 40, cy - 50) withAttributes:attrs];
  }

  UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return result;
}
