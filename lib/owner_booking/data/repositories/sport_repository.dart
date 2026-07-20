import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/data/models/sport_model.dart';

class SportRepository {
  final SupabaseClient _supabase;
  static const String _key = 'sports_cache';

  SportRepository(this._supabase);

  Future<List<SportModel>> fetchSports() async {
    try {
      final response = await _supabase
          .from('sports')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final sports = (response as List)
          .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _cacheSports(sports);

      return sports;
    } catch (e) {
      debugPrint('[SportRepository] Error fetching sports: $e');
      return await _getCachedSports();
    }
  }

  Future<void> _cacheSports(List<SportModel> sports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sports.map((s) => s.toJson()).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[SportRepository] Error caching sports: $e');
    }
  }

  Future<List<SportModel>> _getCachedSports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data == null) return [];
      final jsonList = jsonDecode(data) as List;
      return jsonList
          .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SportRepository] Error reading cached sports: $e');
      return [];
    }
  }
}
