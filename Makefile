# Default prefix for installation
PREFIX ?= /usr/local

build:
	mkdir -p build
	dart compile exe bin/rclone_sync_daemon.dart -o build/rclone-sync-daemon


install: build
	cp build/rclone-sync-daemon $(PREFIX)/bin/rclone-sync-daemon
