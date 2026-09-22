include $(TOPDIR)/rules.mk

PKG_NAME:=minieap
PKG_VERSION:=0.94.2
PKG_RELEASE:=2
PKG_MAINTAINER:=Railgun-wiki <64968531+Railgun-wiki@users.noreply.github.com>
PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DIR:=$(BUILD_DIR)/minieap-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Railgun-wiki/minieap-sysu.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=dev

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Extensible 802.1x client with Ruijie v3 (v4) plugin for SYSU
	MAINTAINER:=Railgun-wiki <64968531+Railgun-wiki@users.noreply.github.com>
	URL:=https://github.com/Railgun-wiki/minieap-sysu
endef

define Package/$(PKG_NAME)/description
	This is an EAP client that implements the SYSU custom EAP-MD5-Challenge algorithm.
	It supports plug-ins to modify standard data packets to authenticate with Ruijie campus servers.
	Enhanced version with OpenWrt syslog/file dual logging, interface link detection and robust state machine retry logic.
endef

define Package/$(PKG_NAME)/conffiles
/etc/minieap.conf
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/minieap $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/minieap.sh $(1)/lib/netifd/proto/
	$(INSTALL_BIN) ./files/minieap.script $(1)/lib/netifd/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/minieap.init $(1)/etc/init.d/minieap
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
