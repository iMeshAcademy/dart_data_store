part of dart_store;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

/// Callback function to perform filter operation.
/// If the return value is [true] then that record will be included in the filtered result.
/// This function accepts [Model] as input parameter.
typedef bool FilterCallback<T extends Model>(T record);

/// Result of a database operation with the [Store] or [Storage]
/// Check  [result] or [error] in order to understand status of the operation.
typedef void DatabaseOperationCallback<T extends Model>(
    dynamic result, dynamic error);

///
/// Mixin, which provide filterable support for the store.
/// Store, by default won't support this mixin.
mixin Filterable<T extends Model> {
  _CacheControl _records_;
  _CacheControl _filteredList_;

  _CacheControl get cachedRecords => _records_;
  _CacheControl get filteredRecords => _filteredList_;

  bool _filtered = false;
  bool _cached = false;
  bool _suspendFilters = false;

  List<dynamic> _filters = List<dynamic>();

  /// List of filters in the filterable collection.
  List<dynamic> get filters => this._filters;

  /// Update list of filters with the collection.
  set filters(List<dynamic> value) => this._filters = value;

  /// API which initializes cache control.
  /// This shall be called prior to use the class.
  void initCache() {
    this._records_ = new _CacheControl(cached);
    this._filteredList_ = new _CacheControl(cached);
  }

  ///
  /// Filter API.
  ///  Use this API to perform filter operation.
  /// [configOrCallback] - a filter configuration or filterCallbackFuntion.
  /// [notify] - Default to true. Supply false if no events need to be fired.
  /// [force] - This parameter is used to perform force filtering. If supplied -
  /// filter operation will be performed without checking internal state.
  ///
  filterBy([dynamic configOrCallback, bool notify = true, bool force]) {
    if (this._suspendFilters) {
      return;
    }
    applyFilter(configOrCallback, notify, force);
  }

  /// This function provide mechanism to filter store entries.
  /// Filters can be based on filter configurations or based on filter callback function.
  /// Refer [filterBy] to check valid configurations.
  @protected
  void applyFilter(dynamic filter,
      [bool fireEvent = true, bool bForce = false]) {
    if (false == cached) {
      // Collection is not cached, so no records to perform filter.
      return;
    }
    // Sanity check the new filter.
    if (null == filter) {
      if (filtered && false == bForce) {
        // Return filtered list if it is already filtered and no new filters are added.
        if (fireEvent && false == this._suspendFilters) onFiltered();
        return;
      }
    } else {
      if (this._filters.contains(filter) == false) {
        // Add to filters if the filter is not present already.
        this._filters.add(filter);
      }
    }

    if (false == hasFilters) {
      if (false == this._suspendFilters) onFilterFailed();
      return;
    }

    this.performFilter(records, (data, error) {
      this.filteredRecords(data);
      this._filtered = true;
      // Emit filter event if it is required in the current operation context.
      if (fireEvent && false == this._suspendFilters) onFiltered();
    });
  }

  ///
  /// Routine which perform filter operation on the collection.
  /// [records] - List of records which needs to be filtered.
  /// [callback] - A callback, which emits success or failure with results.
  ///
  @protected
  void performFilter(List<T> records, DatabaseOperationCallback callback) {
    List<T> filtered = List<T>();
    records.forEach((rec) {
      bool bFiltered = true;
      this.filters.forEach((filter) {
        if (null != filter) {
          if (filter is FilterCallback) {
            bFiltered &= filter(rec);
          } else {
            if (filter is Map<String, dynamic>) {
              dynamic val = rec.getValue(filter["property"]);
              dynamic filterValue = filter["value"];
              bool exactMatch = filter["exactMatch"] ?? true;
              String rule = filter["rule"] ?? "";
              bool caseSensitive = filter["caseSensitive"] ?? false;

              if (false == caseSensitive && (val is String)) {
                val = (val as String).toLowerCase();
                filterValue = (filterValue as String).toLowerCase();
              }

              if (exactMatch) {
                bFiltered &= val == filterValue;
              } else {
                if (rule.isNotEmpty) {
                  // Assuming this is a string comparison.
                  switch (rule) {
                    case "beginsWith":
                      bFiltered &= (val as String).startsWith(filterValue);
                      break;
                    case "endswith":
                      bFiltered &= (val as String).endsWith(filterValue);
                      break;
                    case "contains":
                      bFiltered &= (val as String).contains(filterValue);
                      break;
                  } // Switch
                } // Rule empty.
              } // Not exact match
            } // filter typecast
          } // else config.
        } // Loop for filter map.
      });

      if (bFiltered) {
        filtered.add(rec);
      }
    });

    if (null != callback) {
      callback(filtered, null);
    }
  }

  /// Remove a particular filter by [name] or by [item].
  void removeFilter(String name, dynamic item) {
    if ((null == name || name.isEmpty) || null == item) {
      return;
    }

    int filterLen = this._filters.length;

    this._filters.removeWhere((it) {
      if (item != null) {
        return it == item;
      } else {
        if (it is Map<String, dynamic>) {
          if (it["name"] == name) {
            return true;
          }
        }
      }
      return false;
    });

    if (this._filters.length != filterLen) {
      this._filtered = false; // Need to force filtering.
      this.filterBy();
    }
  }

  /// Remove all cached filters.
  /// Use this API to cleanup your unwanted filters,like search or other filters.
  /// This will not remove any cached filters in the collection.
  void clearTemporaryFilters() {
    int filterLen = this._filters.length;
    this._filters.removeWhere((it) {
      if (it is Map<String, dynamic>) {
        if (it["cached"] == false) {
          return true;
        }
      }
    });
    if (this._filters.length != filterLen) {
      this._filtered = false; // Need to force filtering.
      this.filterBy();
    }
  }

  /// Empty filters. This shall clear all filters.
  void clearFilters() {
    this._filters.clear();
    this._filtered = false;
    if (false == this._suspendFilters) this.onFiltered();
  }

  /// Fire filtered. Implementer of this function can provide appropriate implementation.
  void onFiltered();

  /// Just to notify that filter operation has failed.
  void onFilterFailed();

  /// Suspend filter operation.
  void suspendFilter() {
    this._suspendFilters = true;
  }

  /// Resume filter operation.
  void resumeFilters() {
    this._suspendFilters = false;
  }

  /// Get the filtered status.
  bool get filtered => this._filtered;

  /// Check if any valid filters are there in cache.
  bool get hasFilters => this._filters.isNotEmpty;

  /// Check if cache is enabled for the collection.
  /// If the [cached] value is false, the collection won't store any records.
  bool get cached => this._cached;

  /// Protected API to set cache control.
  @protected
  set cached(bool val) => this._cached = val;

  /// Get the list of records in the collection.
  /// If not cached, the collection will be empty always.
  /// Any operations being performed on the collection, when cache is off, wont be saved.
  List<T> get records => cached
      ? (filtered ? this.filteredRecords.records : this.cachedRecords.records)
      : List<T>();

  /// Get the length of items in collection.
  int get count => records.length;

  /// Get the index of the record in the collection.
  /// Useful when performing update operation.
  int indexOf(T model) => this.records.indexOf(model);
}

// Class which takes care of cache control.
// If store is cached, then this class will provide cache support for the store.
class _CacheControl<T extends Model> implements Function {
  List<T> _cachedRecords = List<T>();
  final bool cached;

  _CacheControl(this.cached);

  void call(dynamic data) {
    if (cached && data is List<T>) {
      this._cachedRecords = data;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is _CacheControl) {
      return other.cached == this.cached &&
          other._cachedRecords == this._cachedRecords;
    }
    return false;
  }

  @override
  int get hashCode =>
      this.cached.hashCode ^ this._cachedRecords.hashCode ^ super.hashCode;

  /// Add records to the cache.
  void add(T model) {
    if (this.cached && false == this._cachedRecords.contains(model)) {
      this._cachedRecords.add(model);
    }
  }

  /// Remove records from cache.
  void remove(T model) {
    if (this.cached && this._cachedRecords.contains(model)) {
      this._cachedRecords.remove(model);
    }
  }

  /// Clear, records from cache.
  void clear() {
    if (this.cached) {
      this._cachedRecords.clear();
    }
  }

  /// Retrieve the index of the particular record in collection.
  int indexOf(T m) => this._cachedRecords.indexOf(m);

  /// Get the records from cache.
  /// Make sure not to perform any operation on the records collection as it is the reference we are getting.
  List<T> get records => this._cachedRecords;
}
