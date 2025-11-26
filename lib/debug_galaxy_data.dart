import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'storage.dart';
import 'galaxy_metadata.dart';
import 'core/utils/app_logger.dart';

/// Debug utility to diagnose galaxy data sync issues
/// Call this from your app when investigating empty galaxy issues
class GalaxyDataDebugger {
  /// Run comprehensive diagnostics and print detailed report
  static Future<void> diagnose() async {
    AppLogger.info('\n${"=" * 80}');
    AppLogger.info('GALAXY DATA DIAGNOSTIC REPORT');
    AppLogger.info('${"=" * 80}\n');
    
    await _checkAuthentication();
    await _checkLocalStars();
    await _checkLocalGalaxyMetadata();
    await _checkFirebaseStars();
    await _checkFirebaseGalaxyMetadata();
    await _analyzeAndRecommend();
    
    AppLogger.info('\n${"=" * 80}');
    AppLogger.info('END DIAGNOSTIC REPORT');
    AppLogger.info('${"=" * 80}\n');
  }
  
  static Future<void> _checkAuthentication() async {
    AppLogger.info('👤 AUTHENTICATION STATUS:');
    AppLogger.info('-' * 80);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.error('   ❌ No user authenticated!');
      return;
    }
    
    AppLogger.success('   ✅ User: ${user.uid}');
    AppLogger.info('   Email: ${user.email ?? "Anonymous"}');
    AppLogger.info('');
  }
  
  static Future<void> _checkLocalStars() async {
    AppLogger.info('📦 LOCAL STORAGE - ALL STARS:');
    AppLogger.info('-' * 80);
    
    try {
      final stars = await StorageService.loadGratitudeStars();
      AppLogger.info('   Total: ${stars.length} stars');
      
      if (stars.isEmpty) {
        AppLogger.warning('   ⚠️  Local storage is EMPTY!');
      } else {
        // Group by galaxy
        final byGalaxy = <String, List<GratitudeStar>>{};
        for (final star in stars) {
          byGalaxy.putIfAbsent(star.galaxyId, () => []).add(star);
        }
        
        AppLogger.info('   By galaxy:');
        for (final entry in byGalaxy.entries) {
          final active = entry.value.where((s) => !s.deleted).length;
          final deleted = entry.value.where((s) => s.deleted).length;
          AppLogger.info('      ${entry.key}: $active active, $deleted deleted');
        }
      }
    } catch (e) {
      AppLogger.error('   ❌ Error: $e');
    }
    AppLogger.info('');
  }
  
  static Future<void> _checkLocalGalaxyMetadata() async {
    AppLogger.info('🌌 LOCAL GALAXY METADATA:');
    AppLogger.info('-' * 80);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString('active_galaxy_id');
      final galaxyJson = prefs.getString('galaxies');
      
      AppLogger.info('   Active galaxy: ${activeId ?? "(none)"}');
      
      if (galaxyJson != null) {
        final galaxies = (jsonDecode(galaxyJson) as List)
            .map((json) => GalaxyMetadata.fromJson(json as Map<String, dynamic>))
            .toList();
        
        AppLogger.info('   Galaxies: ${galaxies.length}');
        for (final g in galaxies) {
          final active = g.id == activeId ? ' (ACTIVE)' : '';
          AppLogger.info('      - ${g.name}$active: ${g.starCount} stars');
        }
      } else {
        AppLogger.warning('   ⚠️  No galaxy metadata found!');
      }
    } catch (e) {
      AppLogger.error('   ❌ Error: $e');
    }
    AppLogger.info('');
  }
  
  static Future<void> _checkFirebaseStars() async {
    AppLogger.info('☁️  FIREBASE STARS:');
    AppLogger.info('-' * 80);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.warning('   ⚠️  Not authenticated');
        return;
      }
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stars')
          .get();
      
      AppLogger.info('   Total: ${snapshot.docs.length} stars');
      
      if (snapshot.docs.isEmpty) {
        AppLogger.warning('   ⚠️  Firebase is EMPTY!');
      } else {
        // Group by galaxy
        final byGalaxy = <String, int>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final galaxyId = data['galaxyId'] as String? ?? 'unknown';
          final deleted = data['deleted'] as bool? ?? false;
          if (!deleted) {
            byGalaxy[galaxyId] = (byGalaxy[galaxyId] ?? 0) + 1;
          }
        }
        
        AppLogger.info('   Active stars by galaxy:');
        for (final entry in byGalaxy.entries) {
          AppLogger.info('      ${entry.key}: ${entry.value} stars');
        }
      }
    } catch (e) {
      AppLogger.error('   ❌ Error: $e');
    }
    AppLogger.info('');
  }
  
  static Future<void> _checkFirebaseGalaxyMetadata() async {
    AppLogger.info('☁️  FIREBASE GALAXY METADATA:');
    AppLogger.info('-' * 80);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.warning('   ⚠️  Not authenticated');
        return;
      }
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('galaxyMetadata')
          .get();
      
      AppLogger.info('   Total: ${snapshot.docs.length} galaxies');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String;
        final starCount = data['starCount'] as int? ?? 0;
        AppLogger.info('      - $name: $starCount stars');
      }
    } catch (e) {
      AppLogger.error('   ❌ Error: $e');
    }
    AppLogger.info('');
  }
  
  static Future<void> _analyzeAndRecommend() async {
    AppLogger.info('🔍 ANALYSIS & RECOMMENDATIONS:');
    AppLogger.info('-' * 80);
    
    try {
      final localStars = await StorageService.loadGratitudeStars();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        final cloudSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('stars')
            .get();
        
        if (localStars.length != cloudSnapshot.docs.length) {
          AppLogger.warning('   ⚠️  MISMATCH: Local ${localStars.length} vs Cloud ${cloudSnapshot.docs.length}');
          if (localStars.length < cloudSnapshot.docs.length) {
            AppLogger.info('      → Local is missing ${cloudSnapshot.docs.length - localStars.length} stars');
            AppLogger.info('      → SOLUTION: Force sync to download missing data');
          } else {
            AppLogger.info('      → Cloud is missing ${localStars.length - cloudSnapshot.docs.length} stars');
            AppLogger.info('      → SOLUTION: Force sync to upload missing data');
          }
        } else {
          AppLogger.success('   ✅ Local and cloud counts match!');
        }
        
        // Check last sync
        final lastSync = await StorageService.getLastSyncTime();
        if (lastSync != null) {
          final minutesAgo = DateTime.now().difference(lastSync).inMinutes;
          AppLogger.info('   Last sync: $minutesAgo minutes ago');
        } else {
          AppLogger.warning('   ⚠️  Never synced!');
        }
      }
    } catch (e) {
      AppLogger.error('   ❌ Error: $e');
    }
    AppLogger.info('');
  }
}

