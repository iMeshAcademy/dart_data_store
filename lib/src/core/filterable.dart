part of dart_store;

typedef bool FilterCallback<T extends Model>(T record);
typedef void DatabaseOperationCallback<T extends Model>(
    dynamic result, dynamic error);

mixin Filterable<T extends Model> {
  _CacheControl _records_;
  _CacheControl _filteredList_;

  _CacheControl get cachedRecords => _records_;
  _CacheControl get filteredRecords => _filteredList_;

  bool _filtered = false;
  bool _cached = false;
  bool _suspendFilters = false;

  List<dynamic> _filters = List<dynamic>();

  List<dynamic> get filters => this._filters;
  set filters(List<dynamic> value) => this._filters = value;

  void initCache() {
    this._records_ = new _CacheControl(cached);
    this._filteredList_ = new _CacheControl(cached);
  }

  void doFilter([dynamic config, bool notify = false, bool force = false]) {
    if (this._suspendFilters) {
      return;
    }
    applyFilter(config, notify, force);
  }

  filterBy([FilterCallback callback, bool notify = false, bool force]) {
    doFilter(callback, notify, force);
  }

  /// This function provide mechanism to filter store entries.
  /// Filters can be based on filter configurations or based on filter callback function.
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
        if (fireEvent) onFiltered();
        return;
      }
    } else {
      if (this._filters.contains(filter) == false) {
        // Add to filters if the filter is not present already.
        this._filters.add(filter);
      }
    }

    if (false == hasFilters) {
      onFilterFailed();
      return;
    }

    this.performFilter(records, (data, error) {
      this.filteredRecords(data);
      this._filtered = true;
      // Emit filter event if it is required in the current operation context.
      if (fireEvent) onFiltered();
    });
  }

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
      this.doFilter();
    }
  }

  // Remove all cached filters.
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
      this.doFilter();
    }
  }

  void clearFilters() {
    this._filters.clear();
    this._filtered = false;
    this.onFiltered();
  }

  void onFiltered();
  void onFilterFailed();

  void suspendFilter() {
    this._suspendFilters = true;
  }

  void resumeFilters() {
    this._suspendFilters = false;
  }

  bool get filtered => this._filtered;
  bool get hasFilters => this._filters.isNotEmpty;
  bool get cached => this._cached;

  @protected
  set cached(bool val) => this._cached = val;

  List<T> get records => cached
      ? filtered ? this.filteredRecords.records : this.cachedRecords.records
      : List<T>();

  int get count => records.length;

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

  void add(T model) {
    if (this.cached && false == this._cachedRecords.contains(model)) {
      this._cachedRecords.add(model);
    }
  }

  void remove(T model) {
    if (this.cached && this._cachedRecords.contains(model)) {
      this._cachedRecords.remove(model);
    }
  }

  void clear() {
    if (this.cached) {
      this._cachedRecords.clear();
    }
  }

  int indexOf(T m) => this._cachedRecords.indexOf(m);

  List<T> get records => this._cachedRecords;
}
