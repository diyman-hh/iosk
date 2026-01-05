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

  // Assuming RGBA 4 bytes per pixel (standard screenshot format usually)
  // Need to correctly calculate offset based on bytesPerRow
  size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
  int pixelInfo = ((int)width * pixelY + pixelX) *
                  4; // Approximation, better to use bytesPerRow
  pixelInfo = (int)(pixelY * bytesPerRow + pixelX * 4);

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
