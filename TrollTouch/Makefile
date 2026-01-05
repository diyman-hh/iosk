TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = TrollTouch

TrollTouch_FILES = main.m
TrollTouch_CFLAGS = -fobjc-arc -I../
TrollTouch_CODESIGN_FLAGS = -Sentitlements.plist
TrollTouch_INSTALL_PATH = /usr/local/bin
TrollTouch_FRAMEWORKS = Foundation IOKit
TrollTouch_PRIVATE_FRAMEWORKS = SpringBoardServices BackBoardServices

include $(THEOS_MAKE_PATH)/tool.mk
