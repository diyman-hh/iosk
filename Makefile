export ARCHS = arm64
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

# Main application (host app)
APPLICATION_NAME = TrollTouch

TrollTouch_FILES = \
	TrollTouch/main.m \
	TrollTouch/AppDelegate.m \
	TrollTouch/RootViewController.m \
	TrollTouch/AutomationManager.m \
	TrollTouch/ScreenCapture.m \
	TrollTouch/VisionHelper.m \
	TouchSimulator.c

TrollTouch_FRAMEWORKS = UIKit CoreGraphics Foundation AVFoundation Vision
TrollTouch_CFLAGS = -fobjc-arc
TrollTouch_LDFLAGS = -lIOKit

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall -9 TrollTouch || true"
