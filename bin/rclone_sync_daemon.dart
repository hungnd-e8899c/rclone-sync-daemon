import 'package:watcher/watcher.dart';
import 'dart:io';
import 'package:args/args.dart' show ArgParser;
import 'dart:async' show Timer;
import 'package:async/async.dart' show StreamGroup;

/// checks if the given path is a mount point.
Future<bool> isMountPoint(String path) async {
  ProcessResult result = await Process.run("mountpoint", [path]);
  return result.exitCode == 0;
}

/// Run sync, the source must be a mounted remote path
Future<int> rcloneSyncToLocal(String source, String target) async {
  final isSourceMount = await isMountPoint(source);

  if (!isSourceMount) {
    print("Source is a mount point, skipping rclone sync.");
    return -1;
  }

  final proc = await Process.start("rclone", [
    "sync",
    source,
    target,
    "--progress",
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await proc.exitCode;
  return exitCode;
}

/// Run sync, the source must be a mounted remote path
Future<int> rcloneSyncToRemote(String source, String target) async {
  final isSourceMount = await isMountPoint(source);

  if (!isSourceMount) {
    print("Source is a mount point, skipping rclone sync.");
    return -1;
  }

  final proc = await Process.start("rclone", [
    "sync",
    target,
    source,
    "--progress",
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await proc.exitCode;
  return exitCode;
}

Future<int> rcloneBiSync({
  required String remotePath,
  required String cachePath,
}) async {
  final isRemoteMount = await isMountPoint(remotePath);

  if (!isRemoteMount) {
    print("One of the paths is not a mount point, skipping");
    return -1;
  }

  final proc = await Process.start("rclone", [
    "sync",
    remotePath,
    cachePath,
    "--progress",
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await proc.exitCode;
  return exitCode;
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'remotePath',
      abbr: 'r',
      valueHelp:
          'Path to the remote directory, must be a rclone mount point, not the remote itself',
    )
    ..addOption(
      'cachePath',
      valueHelp: 'Path to the local cache directory',
      abbr: 'c',
    )
    ..addOption(
      'debounceDuration',
      valueHelp: 'Number of miliseconds after a FS event is detected to sync',
      abbr: 't',
      defaultsTo: '2000',
    );

  final args = parser.parse(arguments);

  final isInvalidArgs =
      args.rest.isNotEmpty ||
      args['remotePath'] == null ||
      args['cachePath'] == null;

  if (isInvalidArgs) {
    print("Usage: rclone_sync_daemon [options]");
    print(parser.usage);
    return;
  }

  final remotePath = args['remotePath'] as String;
  final cachePath = args['cachePath'] as String;

  final remoteDirWatcher = DirectoryWatcher(remotePath);
  final remoteDirEvents = remoteDirWatcher.events;
  final cacheDirWatcher = DirectoryWatcher(cachePath);
  final cacheDirEvents = cacheDirWatcher.events;

  final combinedEvents = StreamGroup.merge([remoteDirEvents, cacheDirEvents]);

  // Sync after a debounce period
  final debouceDuration = Duration(milliseconds: 2000);
  var debouceTimer = Timer(debouceDuration, () {});
  bool fromLocal = false;
  combinedEvents.listen((event) async {
    if (debouceTimer.isActive) {
      debouceTimer.cancel();
    } else {
      // The original chain of synchronization
      fromLocal = event.path.startsWith(cachePath);
    }

    debouceTimer = Timer(debouceDuration, () async {
      int? exitCode;
      print("Change type: ${event.type}");
      print("Detected change:  ${event.path}");
      if (fromLocal) {
        exitCode = await rcloneSyncToRemote(remotePath, cachePath);
      } else {
        exitCode = await rcloneSyncToLocal(remotePath, cachePath);
      }

      switch (exitCode) {
        case 0:
          print("Sync completed successfully.");
        case int _:
          print("Sync failed with exit code: $exitCode");
      }
    });
  });
}
