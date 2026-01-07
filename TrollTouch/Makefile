TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TrollTouch

TrollTouch_FILES = main.m AppDelegate.m RootViewController.m AutomationManager.m ScreenCapture.m VisionHelper.m ../TouchSimulator.c
TrollTouch_CFLAGS = -fobjc-arc -I../
TrollTouch_CODESIGN_FLAGS = -Sentitlements.plist
TrollTouch_FRAMEWORKS = Foundation IOKit UIKit CoreGraphics Vision AVFoundation AudioToolbox CoreLocation
TrollTouch_INFO_PLIST = Info.plist

include $(THEOS_MAKE_PATH)/application.mk
