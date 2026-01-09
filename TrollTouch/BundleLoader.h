//
//  BundleLoader.h
//  Helper to load UITests bundle at runtime
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BundleLoader : NSObject

/// Load the UITests bundle from PlugIns directory
+ (BOOL)loadUITestsBundle;

/// Check if UITests bundle is loaded
+ (BOOL)isUITestsBundleLoaded;

@end

NS_ASSUME_NONNULL_END
