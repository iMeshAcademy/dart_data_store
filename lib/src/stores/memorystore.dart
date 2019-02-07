part of dart_store;

class MemoryStore<T extends Model> extends Store<T>
    with Filterable<T>, Sortable<T> {
  bool _loaded = false;
  MemoryStore(dynamic config) : super(config) {
    if (this.storage != null && this.storage.isOpen == false) {
      this.storage.open((status, data) {});
    }
  }

  @override
  bool get isLoaded => this._loaded;

  @override
  void performAdd(record, DatabaseOperationCallback callback) {
    if (cached) {
      record.key = "${record.modelName}__id__$count";
      super.cachedRecords.add(record);
      callback(1, null);
    } else {
      callback(0, "Store is not cached.");
    }
  }

  @override
  void performCommit(DatabaseOperationCallback callback) {
    callback(1, null);
  }

  @override
  void performLoad(DatabaseOperationCallback callback) {
    if (cached) {
      _loaded = true;
      callback(records, null);
    } else {
      callback(null, "Store is not cached.");
    }
  }

  @override
  void performRemove(record, DatabaseOperationCallback callback) {
    if (cached) {
      super.cachedRecords.remove(record);
      super.filteredRecords.remove(record);
      callback(1, null);
    } else {
      callback(null, "Store is not cached!");
    }
  }

  @override
  void performRemoveAll(DatabaseOperationCallback callback) {
    if (cached) {
      super.cachedRecords.clear();
      super.filteredRecords.clear();
      callback(1, null);
    } else {
      callback(0, "Store is not cached!");
    }
  }

  @override
  void performUpdate(record, DatabaseOperationCallback callback) {
    callback(cached ? 1 : 0, cached ? null : "Store is not cached");
  }

  @override
  void filter([dynamic config, bool fireEvent = true, bool force]) {
    filterBy(config, fireEvent, force);
  }

  @override
  void parseConfigInternal() {
    if (null != this.config) {
      if (config is Map<String, dynamic>) {
        Map<String, dynamic> data = config as Map<String, dynamic>;
        data.forEach((str, val) {
          switch (str) {
            case "cached":
              this.cached = val;
              super.initCache(); // Instantiate the list and other details.
              break;
            case "filters":
              if (val is List<dynamic>) {
                val.forEach((item) {
                  this.filters.add(item);
                });
              }
              break;
            case "sorters":
              if (val is List<dynamic>) {
                val.forEach((item) {
                  this.sorters.add(item);
                });
              }
              break;
          }
        });
      }
    }
  }

  @override
  void sort([dynamic config, bool fireEvent = true, bool force]) {
    super.applySorter(records, config, fireEvent, force);
  }

  @override
  void onFilterFailed() {
    emit("error", this, new DatabaseError("filter", "Filter failed", null));
  }

  @override
  void onFiltered() {
    emit("filter", this, records);
  }

  @override
  void onSortFailed() {
    emit("error", this,
        new DatabaseError("sort", "Sort operation failed.", null));
  }

  @override
  void onSorted() {
    emit("sort", this);
  }

  @override
  bool get isFiltered => this.filtered;

  @override
  bool get isSorted => this.sorted;
}
