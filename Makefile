TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = QunariPhone_Cook_CM

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QunarJBBypass
QunarJBBypass_FILES = Tweak.x
QunarJBBypass_CFLAGS = -fobjc-arc
QunarJBBypass_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
