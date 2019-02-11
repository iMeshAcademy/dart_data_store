part of dart_store;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

/// Mixin, which provides collection implemetation for store.
/// Refer [MemoryStore] to understand the usage of [ModelCollection].
mixin ModelCollection<T extends Model> {
  // Private instance of collection, with a dynamic return type and has input type Model.
  Collection<dynamic, T> _collection = new Collection<dynamic, T>();

  /// Get filters associated with collection.
  List<dynamic> get filters => _collection.filters;

  /// Set filters to collection. Make sure that valid filter config is passed in this setter.
  set filters(List<dynamic> values) => this._collection.filters = values;

  /// Sorter cofigurations associated with the collection.
  List<dynamic> get sorters => this._collection.sorters;

  /// Setter for sort configuration for the collection.
  set sorters(List<dynamic> values) => this._collection.sorters = values;

  bool _cached = false;

  /// Whether the collection should be cached.
  /// This is read from the store configuration passed in the [Config.initialize] function
  set cached(bool val) => this._cached = val;
  bool get cached => this._cached;

  /// Callback which shall be raised when the collection get's modified.
  /// This callback will be raised for the following events.
  /// ["add","remove","clear","sort","error","load","filter"]
  void onCollectionModifiedCallback(Event ev, Object context) {
    this.notifyCollectionModified(ev, context);
  }

  /// List of events supported for the collection. Extend this list if it need more events.
  final List<String> _eventsForCollection = [
    "add",
    "remove",
    "clear",
    "sort",
    "error",
    "load",
    "filter"
  ];

  /// A Event handler for collection.
  /// This shall be implemented in the derived class and appropriate events should be handled there.
  ///
  /// Refer [MemoryStore] for details.
  void notifyCollectionModified(Event ev, Object context);

  /// Initialize cache configuration. Called by the derived class while configuring it. Refer [MemoryStore.parseConfigInternal] function for details.
  void initCache(bool cac) {
    this.cached = cac;
    if (this.cached) {
      this._eventsForCollection.forEach((ev) {
        this._collection.on(ev, this, this.onCollectionModifiedCallback);
      });
    } else {
      this._collection.clear();
    }
  }

  ///
  /// Load records to collection. This is usually called when the collection is being loaded initially or database is refreshed for latest records.
  ///
  void loadRecords(List<T> records, CollectionOperationCallback callback) {
    this._collection.load(records, callback);
  }

  /// An async version of the loadRecords API.
  Future loadRecordsAsync(List<T> records) {
    return new Future(() {
      this.loadRecords(records, null);
    });
  }

  /// Add records to the collection.
  void addRecord(T record, CollectionOperationCallback callback) {
    if (this.cached) {
      this._collection.add(record, callback);
    }
  }

  /// Async version of [addRecord] API.
  Future<void> addRecordAsync(T record) {
    return new Future(() {
      this.addRecord(record, null);
    });
  }

  /// Remove records from collection.
  void removeRecord(T record, CollectionOperationCallback callback) {
    if (this.cached) {
      this._collection.remove(record, callback);
    }
  }

  /// Async version of [removeRecord] API.
  Future<void> removeRecordAsync(T record) {
    return new Future(() {
      return this.removeRecord(record, null);
    });
  }

  /// Update collection records.
  void updateRecord(T record, CollectionOperationCallback callback) {
    if (this.cached) {
      this._collection.update(record, callback);
    }
  }

  /// Async version of [updateRecord] API
  Future<void> updateRecordAsync(T record) {
    return new Future(() {
      return this.updateRecord(record, null);
    });
  }

  /// Remove all records from collection.
  void removeAllRecords(CollectionOperationCallback callback) {
    if (this.cached) {
      this._collection.clearRecords(callback);
    }
  }

  /// Async version of [removeAllRecords] API.
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

  ///
  /// Suspend sort operation.
  ///
  void supendSort() {
    this._collection.supendSort();
  }

  ///
  /// Resume sort operation.
  ///
  void resumeSort() {
    this._collection.resumeSort();
  }

  ///
  /// Remove sorter from collection.
  ///
  void removeSorter(dynamic sorter) {
    this._collection.removeSorter(sorter);
  }

  /// Clear all sorters from collection.
  void clearSorters() {
    this._collection.clearSorters();
  }

  /// Remove particular sorter using the name provided in the "store" config in the [Config.initialize] api.
  void removeSorterByName(String name) {
    return this._collection.removeSorterByName(name);
  }

  /// Enable sorter by name or callback.
  void enableSorter(dynamic value) {
    this._collection.enableSorter(value);
  }

  /// Disable all sorters.
  void disableAllSorters() {
    this._collection.disableAllSorters();
  }

  /// Enable all sorters.
  void enableAllSorters() {
    this._collection.enableAllSorters();
  }

  /// Disable particular sorter either by name or callback.
  void disableSorter(dynamic value) {
    this._collection.disableSorter(value);
  }

  /// API to perform sorting on the collection.
  void sortCollection(
      [dynamic config, bool fireEvent = true, bool force = false]) {
    this._collection.sort(config, fireEvent, force);
  }

  /// Retrieve the index of the particular record in collection.
  int indexOf(T rec) => this._collection.indexOf(rec);

  /// Retrieve the records from collection.
  List<T> get records => this._collection.records;

  ///
  /// Retrieve all records from collection, just in case we need it.
  /// This is not a shallow copy and any changes made to this records, will affect the internal cache.
  /// NOTE - Take caution while using the value from this getter.
  ///
  List<T> get allRecords => this._collection.getAllRecords();

  /// Flag to identify if collection is filtered.
  bool get filtered => this._collection.filtered;

  /// Flag to identify if collection is sorted.
  bool get sorted => this._collection.sorted;
}
