import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  /// Create - දත්ත ඇතුළත් කිරීම
  Future<void> insertData(String tableName, Map<String, dynamic> data) async {
    try {
      await _supabase.from(tableName).insert(data);
    } catch (e) {
      throw Exception('Insert Error in $tableName: $e');
    }
  }

  /// Read - Realtime Stream ලබා ගැනීම
  Stream<List> getStream(
    String tableName, {
    String orderBy = 'created_at',
    bool ascending = false,
  }) {
    return _supabase
        .from(tableName)
        .stream(primaryKey: ['id'])
        .order(orderBy, ascending: ascending);
  }

  /// Read - Query එකක් මඟින් දත්ත ලබා ගැනීම
  Future<List> getDataWithQuery(
    String tableName, {
    String? column,
    dynamic value,
  }) async {
    try {
      var query = _supabase.from(tableName).select();

      if (column != null && value != null) {
        query = query.eq(column, value);
      }

      return List.from(await query);
    } catch (e) {
      throw Exception('Fetch Error in $tableName: $e');
    }
  }

  /// Update - විස්තර වෙනස් කිරීම
  Future<void> updateData(
    String tableName,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _supabase.from(tableName).update(data).eq('id', id);
    } catch (e) {
      throw Exception('Update Error in $tableName: $e');
    }
  }

  /// Delete - දත්ත මකා දැමීම
  Future<void> deleteData(String tableName, String id) async {
    try {
      await _supabase.from(tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('Delete Error in $tableName: $e');
    }
  }

  // Join Queries හරහා ඩේටා ලබා ගැනීමට (උදා: farmer_stocks සහ master_items එකතු කර ගැනීමට)
  Future<List> getDataWithJoin(
    String tableName, {
    required String selectQuery,
    String? filterColumn,
    dynamic filterValue,
  }) async {
    try {
      var query = _supabase.from(tableName).select(selectQuery);

      if (filterColumn != null && filterValue != null) {
        query = query.eq(filterColumn, filterValue);
      }

      return List.from(await query);
    } catch (e) {
      throw Exception('Join Fetch Error in $tableName: $e');
    }
  }

  /// RPC - Database Functions (Transactions) ක්‍රියාත්මක කිරීම
  Future<void> callRpc(String functionName, Map<String, dynamic> params) async {
    try {
      await _supabase.rpc(functionName, params: params);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
