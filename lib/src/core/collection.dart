part of dart_store;

class Collection<T extends Model>
    with Filterable<T>, Sortable<T>, EventEmitter {
  List<T> _allRecords = List<T>();
  List<T> _filteredRecords = List<T>();

  bool _filtered = false;
  bool get filtered => this._filtered;

  bool _suspendFilters = false;

  bool _sorted = false;
  bool get sorted => _sorted;

  @override
  void onFilterFailed() {
    // Check the reason why filter is failed.
    // Filter might have failed because the list is empty or no filters.
    // Update fields accordingly.

    if (this.getAllRecords().isEmpty || false == hasFilters) {
      this._filteredRecords = List<T>();
      this._filtered = false;
    }

    emit("error", this,
        new DatabaseError("filter", "Filter operation failed", null));
  }

  @override
  void onFiltered(List<T> data, [bool notify = false]) {
    this._filtered = this._allRecords.isNotEmpty && this.hasFilters;
    this._filteredRecords = data;

    if (notify) emit("filter", this, this.records);
  }

  @override
  void onSortFailed() {
    this._sorted = false;
    emit("error", this,
        new DatabaseError("sort", "Sort operation failed", null));
  }

  @override
  void onSorted() {
    this._sorted = true;
    emit("sort", this);
  }

  @override
  List<T> getAllRecords() {
    return this._allRecords;
  }

  @override
  List<T> getFilteredRecords() {
    return this._filteredRecords;
  }

  @override
  void onFiltersCleared() {
    this._filteredRecords.clear();
    this._filtered = false;
    emit("filter", this, records);
  }

  List<Model> get records => this._filtered
      ? getFilteredRecords().sublist(0)
      : getAllRecords().sublist(0);

  void load(List<T> records, DatabaseOperationCallback callback) {
    if (null != records) {
      this._allRecords = records;
      applySorter(this._allRecords, null, false);
      applyFilter(null, false);
      if (null != callback) {
        callback(this.records, null);
      }
      emit("load", this, this._allRecords);
    } else {
      if (null != callback) {
        callback(this.records,
            new DatabaseError("load", "Collection can't be null", null));
      }
      emit("error", this,
          new DatabaseError("load", "Collection can't be null", null));
    }
  }

  void add(T rec, DatabaseOperationCallback callback) {
    this._allRecords.add(rec);
    applySorter(this._allRecords, null, false, true);
    if (this.filtered || hasFilters) {
      applyFilter(null, false, true);
    }
    if (null != callback) {
      callback(1, null);
    }
    emit("add", this, rec);
  }

  /// Remove records from cache.
  void remove(T model, DatabaseOperationCallback callback) {
    if (null != model && this._allRecords.contains(model)) {
      this._allRecords.remove(model);
      if (this.filtered) {
        applyFilter(null, false, true);
      }
      if (null != callback) {
        callback(1, null);
      }
      emit("remove", this, model);
    } else {
      if (null != callback) {
        callback(
            0,
            new DatabaseError(
                "remove", "Record - $model doesn't exist in database.", model));
      }
      emit(
          "error",
          this,
          new DatabaseError(
              "remove", "Record - $model doesn't exist in database.", model));
    }
  }

  void update(T model, DatabaseOperationCallback callback) {
    int index = -1;
    if (null != model) {
      String key = model.key;
      index = this._allRecords.indexWhere((m) => m.key == key);
    }

    if (index >= 0) {
      this._allRecords.replaceRange(index, index + 1, [model]);
      applySorter(this._allRecords, null, false, true);
      applyFilter(null, false, true);
      if (null != callback) {
        callback(1, null);
      }

      emit("update", this, model);
    } else {
      if (null != callback) {
        callback(
            0,
            new DatabaseError(
                "update", "The record $model doesn't exist", model));
      }
      emit(
          "error",
          this,
          new DatabaseError(
              "update", "The record $model doesn't exist", model));
    }
  }

  void clearRecords(DatabaseOperationCallback callback) {
    this._allRecords.clear();
    applySorter(this._allRecords, null, false, true);
    applyFilter(null, false, true);
    if (null != callback) {
      callback(1, null);
    }
    emit("clear", this, this._allRecords);
  }

  void sort([dynamic config, bool fireEvent = true, bool force = false]) {
    applySorter(this._allRecords, config, fireEvent, force);
  }

  void filter(
      [dynamic configOrCallback, bool notify, bool force, dynamic data]) {
    filterBy(configOrCallback, notify, force, data);
  }

  int indexOf(T rec) => this.records.indexOf(rec);
}

mixin ModelCollection<T extends Model> {
  Collection<T> _collection = new Collection<T>();

  List<dynamic> get filters => _collection.filters;
  set filters(List<dynamic> values) => this._collection.filters = values;

  List<dynamic> get sorters => this._collection.sorters;
  set sorters(List<dynamic> values) => this._collection.sorters = values;

  bool _cached = false;
  set cached(bool val) => this._cached = val;
  bool get cached => this._cached;

  void onCollectionModifiedCallback(Event ev, Object context) {
    this.notifyCollectionModified(ev, context);
  }

  void notifyCollectionModified(Event ev, Object context);

  void initCache(bool cac) {
    this.cached = cac;
    if (this.cached) {
      this._collection.on("add", this, this.onCollectionModifiedCallback);
      this._collection.on("remove", this, this.onCollectionModifiedCallback);
      this._collection.on("update", this, this.onCollectionModifiedCallback);
      this._collection.on("clear", this, this.onCollectionModifiedCallback);
      this._collection.on("sort", this, this.onCollectionModifiedCallback);
      this._collection.on("error", this, this.onCollectionModifiedCallback);
      this._collection.on("load", this, this.onCollectionModifiedCallback);
      this._collection.on("filter", this, this.onCollectionModifiedCallback);
    } else {
      this._collection.clear();
    }
  }

  void loadRecords(List<T> records, DatabaseOperationCallback callback) {
    this._collection.load(records, callback);
  }

  Future loadRecordsAsync(List<T> records) {
    return new Future(() {
      this.loadRecords(records, null);
    });
  }

  void addRecord(T record, DatabaseOperationCallback callback) {
    if (this.cached) {
      this._collection.add(record, callback);
    }
  }

  Future<void> addRecordAsync(T record) {
    return new Future(() {
      this.addRecord(record, null);
    });
  }

  void removeRecord(T record, DatabaseOperationCallback callback) {
    if (this.cached) {
      this._collection.remove(record, callback);
    }
  }

  Future<void> removeRecordAsync(T record) {
    return new Future(() {
      return this.removeRecord(record, null);
    });
  }

  void updateRecord(T record, DatabaseOperationCallback callback) {
    if (this.cached) {
      this._collection.update(record, callback);
    }
  }

  Future<void> updateRecordAsync(T record) {
    return new Future(() {
      return this.updateRecord(record, null);
    });
  }

  void removeAllRecords(DatabaseOperationCallback callback) {
    if (this.cached) {
      this._collection.clearRecords(callback);
    }
  }

  Future<void> removeAllRecordsAsync() {
    return new Future(() {
      return this.removeAllRecords(null);
    });
  }

  /// Remove a particular filter by [name] or by [item].
  void removeFilter(String name, dynamic item) {
    this._collection.removeFilter(name, item);
  }

  /// Remove all cached filters.
  /// Use this API to cleanup your unwanted filters,like search or other filters.
  /// This will not remove any cached filters in the collection.
  void clearTemporaryFilters() {
    this._collection.clearTemporaryFilters();
  }

  /// Empty filters. This shall clear all filters.
  void clearFilters() {
    this._collection.clearFilters();
  }

  /// Suspend filter operation.
  void suspendFilter() {
    this._collection.suspendFilter();
  }

  /// Resume filter operation.
  void resumeFilters() {
    this._collection.resumeFilters();
  }

  ///
  /// Filter API.
  ///  Use this API to perform filter operation.
  /// [configOrCallback] - a filter configuration or filterCallbackFuntion.
  /// [notify] - Default to true. Supply false if no events need to be fired.
  /// [force] - This parameter is used to perform force filtering. If supplied -
  /// filter operation will be performed without checking internal state.
  ///
  filterBy(
      [dynamic configOrCallback,
      bool notify,
      bool force,
      dynamic data = null]) {
    this._collection.filter(configOrCallback, notify, force, data);
  }

  void supendSort() {
    this._collection.supendSort();
  }

  void resumeSort() {
    this._collection.resumeSort();
  }

  void removeSorter(dynamic sorter) {
    this._collection.removeSorter(sorter);
  }

  void clearSorters() {
    this._collection.clearSorters();
  }

  void removeSorterByName(String name) {
    return this._collection.removeSorterByName(name);
  }

  void enableSorter(dynamic value) {
    this._collection.enableSorter(value);
  }

  void disableAllSorters() {
    this._collection.disableAllSorters();
  }

  void enableAllSorters() {
    this._collection.enableAllSorters();
  }

  void disableSorter(dynamic value) {
    this._collection.disableSorter(value);
  }

  void sortCollection(
      [dynamic config, bool fireEvent = true, bool force = false]) {
    this._collection.sort(config, fireEvent, force);
  }

  /// Retrieve the index of the particular record in collection.
  int indexOf(T rec) => this._collection.indexOf(rec);

  List<T> get records => this._collection.records;

  List<T> get allRecords => this._collection.getAllRecords();

  bool get filtered => this._collection.filtered;
  bool get sorted => this._collection._sorted;
}
