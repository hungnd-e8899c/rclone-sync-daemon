import 'dart:async';
import 'dart:io';

const rcloneExecutable = 'rclone';

void rcloneMount(remoteName, mountPoint) async {}

class RcloneConfig {
  // Name of the remote storage
  final String remoteName;

  // Path to mount the remote storage
  final String mountPath;

  // Local caching path
  final String cachePath;

  const RcloneConfig({
    required this.remoteName,
    required this.mountPath,
    required this.cachePath,
  });

  void syncToRemote() async {}
  void syncToLocal() async {}

  void startWatching() async {}
}

