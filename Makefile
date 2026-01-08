export ARCHS = arm64
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

# Main application (host app)
APPLICATION_NAME = TrollTouch

TrollTouch_FILES = \
	TrollTouch/main.m \
	TrollTouch/AppDelegate.m \
	TrollTouch/RootViewController.m \
	TrollTouch/XCTestRunner.m \
	TrollTouch/ScheduleManager.m

TrollTouch_FRAMEWORKS = UIKit CoreGraphics Foundation
TrollTouch_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk

# XCTest Bundle
BUNDLE_NAME = TrollTouchUITests
TrollTouchUITests_FILES = TrollTouchUITests/TrollTouchUITests.m
TrollTouchUITests_INSTALL_PATH = /Applications/TrollTouch.app/PlugIns
TrollTouchUITests_FRAMEWORKS = XCTest
TrollTouchUITests_BUNDLE_EXTENSION = xctest
TrollTouchUITests_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 TrollTouch || true"
