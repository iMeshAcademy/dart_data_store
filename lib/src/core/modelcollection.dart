part of dart_store;

mixin ModelCollection<T extends Model> {
  Collection<dynamic, T> _collection = new Collection<dynamic, T>();

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

  void loadRecords(List<T> records, CollectionOperationCallback callback) {
    this._collection.load(records, callback);
  }

  Future loadRecordsAsync(List<T> records) {
    return new Future(() {
      this.loadRecords(records, null);
    });
  }

  void addRecord(T record, CollectionOperationCallback callback) {
    if (this.cached) {
      this._collection.add(record, callback);
    }
  }

  Future<void> addRecordAsync(T record) {
    return new Future(() {
      this.addRecord(record, null);
    });
  }

  void removeRecord(T record, CollectionOperationCallback callback) {
    if (this.cached) {
      this._collection.remove(record, callback);
    }
  }

  Future<void> removeRecordAsync(T record) {
    return new Future(() {
      return this.removeRecord(record, null);
    });
  }

  void updateRecord(T record, CollectionOperationCallback callback) {
    if (this.cached) {
      this._collection.update(record, callback);
    }
  }

  Future<void> updateRecordAsync(T record) {
    return new Future(() {
      return this.updateRecord(record, null);
    });
  }

  void removeAllRecords(CollectionOperationCallback callback) {
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
  bool get sorted => this._collection.sorted;
}
