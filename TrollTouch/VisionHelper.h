#import <UIKit/UIKit.h>
#import <Vision/Vision.h>

// --- Visual Analysis ---

// Check if a specific point (x, y) matches a target color (with tolerance)
// coordinates are 0.0-1.0 relative
BOOL isPixelColor(UIImage *image, float x, float y, float r, float g, float b);

// Check if the current page looks like the Video Feed (Dark background)
BOOL isVideoFeed(UIImage *image);

// --- OCR ---

// Perform OCR on the full image or a region
// Returns a string of all detected text
void recognizeText(UIImage *image, void (^completion)(NSString *result));
