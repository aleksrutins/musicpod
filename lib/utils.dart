import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:musicpod/app/common/audio_filter.dart';
import 'package:musicpod/data/audio.dart';
import 'package:musicpod/l10n/l10n.dart';
import 'package:xdg_directories/xdg_directories.dart';

import 'app/common/constants.dart';

String formatTime(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));

  return <String>[if (duration.inHours > 0) hours, minutes, seconds].join(':');
}

String createPlaylistName(
  String name,
  BuildContext context,
) {
  return name == 'likedAudio' ? context.l10n.likedSongs : name;
}

bool listsAreEqual(List<dynamic>? list1, List<dynamic>? list2) =>
    const ListEquality().equals(list1, list2);

void sortListByAudioFilter({
  required AudioFilter audioFilter,
  required List<Audio> audios,
}) {
  switch (audioFilter) {
    case AudioFilter.artist:
      audios.sort((a, b) {
        if (a.artist != null && b.artist != null) {
          return a.artist!.compareTo(b.artist!);
        }
        return 0;
      });
      break;
    case AudioFilter.title:
      audios.sort((a, b) {
        if (a.title != null && b.title != null) {
          return a.title!.compareTo(b.title!);
        }
        return 0;
      });
      break;
    case AudioFilter.album:
      audios.sort((a, b) {
        if (a.album != null && b.album != null) {
          final albumComp = a.album!.compareTo(b.album!);
          if (albumComp == 0 &&
              a.trackNumber != null &&
              b.trackNumber != null) {
            final trackComp = a.trackNumber!.compareTo(b.trackNumber!);

            return trackComp;
          }
          return albumComp;
        }
        return 0;
      });
      break;
    default:
      audios.sort((a, b) {
        if (a.trackNumber != null && b.trackNumber != null) {
          return a.trackNumber!.compareTo(b.trackNumber!);
        }
        return 0;
      });
      break;
  }
}

Future<String> getWorkingDir() async {
  final workingDir = '${configHome.path}/$kMusicPodConfigSubDir';
  if (!Directory(workingDir).existsSync()) {
    await Directory(workingDir).create();
  }
  return workingDir;
}

Future<void> writeSetting(
  String? key,
  dynamic value,
) async {
  if (key == null || value == null) return;
  final oldSettings = await getSettings();
  if (oldSettings.containsKey(key)) {
    oldSettings.update(key, (v) => value);
  } else {
    oldSettings.putIfAbsent(key, () => value);
  }
  final jsonStr = jsonEncode(oldSettings);

  final workingDir = await getWorkingDir();

  final file = File('$workingDir/settings.json');

  if (!file.existsSync()) {
    file.create();
  }

  await file.writeAsString(jsonStr);
}

Future<dynamic> readSetting(dynamic key) async {
  if (key == null) return null;
  final oldSettings = await getSettings();
  return oldSettings[key];
}

Future<Map<String, String>> getSettings() async {
  final workingDir = await getWorkingDir();

  final file = File('$workingDir/settings.json');

  if (file.existsSync()) {
    final jsonStr = await file.readAsString();

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;

    final m = map.map(
      (key, value) => MapEntry<String, String>(
        key,
        value,
      ),
    );

    return m;
  } else {
    return <String, String>{};
  }
}

Duration? parseDuration(String? durationAsString) {
  if (durationAsString == null || durationAsString == 'null') return null;
  int hours = 0;
  int minutes = 0;
  int micros;
  List<String> parts = durationAsString.split(':');
  if (parts.length > 2) {
    hours = int.parse(parts[parts.length - 3]);
  }
  if (parts.length > 1) {
    minutes = int.parse(parts[parts.length - 2]);
  }
  micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
  return Duration(hours: hours, minutes: minutes, microseconds: micros);
}
