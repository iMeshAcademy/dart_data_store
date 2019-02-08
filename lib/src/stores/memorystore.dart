part of dart_store;

class MemoryStore<T extends Model> extends Store<T> with ModelCollection<T> {
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
    record.key = "${record.modelName}__id__${this.allRecords.length}";
    addRecord(record, callback);
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
    removeRecord(record, callback);
  }

  @override
  void performRemoveAll(DatabaseOperationCallback callback) {
    removeAllRecords(callback);
  }

  @override
  void performUpdate(record, DatabaseOperationCallback callback) {
    updateRecord(record, callback);
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
              initCache(this.cached); // Instantiate the list and other details.
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
    // Not performing sorting as collection is auto sortable.
    super.sortCollection(config, fireEvent, force);
  }

  @override
  bool get isFiltered => this.filtered;

  @override
  bool get isSorted => this.sorted;

  @override
  void notifyCollectionModified(Event ev, Object context) {
    switch (ev.eventName) {
      case "filter":
      case "sort":
      case "clear":
        emit(ev.eventName, this, ev.eventData);
    }
  }

  @override
  int get recordCount => this.records.length;

  @override
  void filterInternal() {
    /// Internal filter API which will be called by store.
  }

  @override
  void sortInternal() {
    /// Internal sort API which will be called by store.
  }
}
