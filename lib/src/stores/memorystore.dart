part of dart_store;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

///
/// Default in-memory store for the dart_store library.
/// This is pretty much needed for almost all requirements.
/// This supports sorting, filtering and almost all functionality a store need to perform.
///
/// This is extended form [ModelCollection] mixin.
///
class MemoryStore<T extends Model> extends Store<T> with ModelCollection<T> {
  bool _loaded = false;

  /// Default constructor which accepts a configuration.
  MemoryStore(dynamic config) : super(config) {
    if (this.storage != null && this.storage.isOpen == false) {
      this.storage.open((status, data) {});
    }
  }

  /// Getter to identify if the store is loaded.
  @override
  bool get isLoaded => this._loaded;

  /// Internal API to perform addition.
  @override
  @protected
  void performAdd(record, CollectionOperationCallback callback) {
    record.key = "${record.modelName}__id__${this.allRecords.length}";
    addRecord(record, callback);
  }

  /// Api to perform commit.
  @protected
  @override
  void performCommit(CollectionOperationCallback callback) {
    callback(1, null);
  }

  /// API to perform load.
  @protected
  @override
  void performLoad(CollectionOperationCallback callback) {
    if (cached) {
      _loaded = true;
      callback(records, null);
    } else {
      callback(null, "Store is not cached.");
    }
  }

  /// API to perform remove.
  @protected
  @override
  void performRemove(record, CollectionOperationCallback callback) {
    removeRecord(record, callback);
  }

  /// API to perform remove all entry from store.
  @protected
  @override
  void performRemoveAll(CollectionOperationCallback callback) {
    removeAllRecords(callback);
  }

  /// API to update an entry to store.

  @protected
  @override
  void performUpdate(record, CollectionOperationCallback callback) {
    updateRecord(record, callback);
  }

  /// API to perform filter logic.
  /// [MemoryStore] uses [Filterable] interface logic for filtering.
  @override
  void filter(
      [dynamic config,
      bool fireEvent = true,
      bool force,
      dynamic data = null]) {
    filterBy(config, fireEvent, force, data);
  }

  /// API to perform config parsing for the store.
  @override
  @protected
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

  /// Sort the store.
  /// [MemoryStore] extends [Sortable.sortCollection] and uses the sort logic provided by it.
  @override
  void sort([dynamic config, bool fireEvent = true, bool force]) {
    // Not performing sorting as collection is auto sortable.
    super.sortCollection(config, fireEvent, force);
  }

  /// Getter to identify filtered state
  @override
  bool get isFiltered => this.filtered;

  /// Getter to identify loaded state.
  @override
  bool get isSorted => this.sorted;

  /// Implemented from [ModelCollection] mixin.
  /// Provide any custom logic for the collection events.
  /// Usually this events might be bubbled to the top level or
  /// to other observers.
  @override
  void notifyCollectionModified(Event ev, Object context) {
    print(ev.eventName);
    switch (ev.eventName) {
      case "filter":
      case "sort":
      case "clear":
        emit(ev.eventName, this, ev.eventData);
    }
  }

  /// Records count of the store.
  /// If store is filtered, then this will show filtered records count.
  /// It will show regular count otherwise.
  @override
  int get recordCount => this.records.length;

  /// Provide filteration logic. This is taken care by [ModelCollection] class.
  @protected
  @override
  void filterInternal() {
    /// Internal filter API which will be called by store.
    /// Do nothing as memory store already supports filterable collections.
  }

  /// Provide sort logic. This is taken care by [ModelCollection] mixin.
  @override
  void sortInternal() {
    /// Internal sort API which will be called by store.
    /// Do nothing, as memory store already supports sortable collections.
  }

  ///
  /// Retrieve all records associated with the store.
  /// This will be filtered records if store is filtered, otherwise will have actual records.
  ///
  @override
  List<Model> getRecords() {
    return this.records; // Assuming that store is already loaded.
  }

  /// Async version of [getRecords] api.
  @override
  Future<List<Model>> getRecordsAsync() {
    if (false == this.isLoaded) {
      return this.loadAsync().then((res) {
        return this.records;
      }).catchError((err) {
        return this.records;
      });
    } else {
      return new Future(() {
        return this.records;
      });
    }
  }
}
