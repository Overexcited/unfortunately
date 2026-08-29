import 'dart:async';
import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/foundation.dart';

class PremiumManager {
final ValueNotifier<bool?> hasPremiumNotifier = ValueNotifier(null);

Future<void> init() async {
hasPremiumNotifier.value = true;
}

Future<bool> _readPremiumStatus() async {
return true;
}

Future<void> updateGitHubSponsorPremium() async {
if (!await hasNetworkConnection()) {
return;
}

final userToken = await repoManager.getStringNullable(StorageKey.repoman_ghSponsorToken);
if (userToken == null) {
  await repoManager.setBool(StorageKey.repoman_hasGHSponsorPremium, false);
  hasPremiumNotifier.value = await _readPremiumStatus();
  return;
}

final userRes = await httpGet(
  Uri.parse('https://api.github.com/user'),
  headers: {'Authorization': 'token $userToken', 'Accept': 'application/vnd.github.v3+json'},
);

if (userRes.statusCode != 200 && userRes.statusCode != 408) {
  await repoManager.setBool(StorageKey.repoman_hasGHSponsorPremium, false);
  hasPremiumNotifier.value = await _readPremiumStatus();
}

if (userRes.statusCode != 200) return;

final userNodeId = jsonDecode(userRes.body)['node_id'].toString();

final fileRes = await httpGet(Uri.parse('https://raw.githubusercontent.com/ViscousPot/sponsors-gitsync/refs/heads/main/sponsors.txt'));

if (userNodeId.isEmpty || (fileRes.statusCode != 200 && fileRes.statusCode != 408)) {
  await repoManager.setBool(StorageKey.repoman_hasGHSponsorPremium, false);
  hasPremiumNotifier.value = await _readPremiumStatus();
}

if (userRes.statusCode != 200) {
  throw Exception('Failed to load sponsors.txt: ${fileRes.statusCode}');
}

final content = utf8.decode(fileRes.bodyBytes);
final lines = LineSplitter.split(content).map((e) => e.trim()).toList();
final isSponsor = lines.contains(userNodeId);

await repoManager.setBool(StorageKey.repoman_hasGHSponsorPremium, isSponsor);
hasPremiumNotifier.value = await _readPremiumStatus();

}

Future<bool> cullNonPremium() async {
return false;
}

void dispose() async {
hasPremiumNotifier.dispose();
}
}
