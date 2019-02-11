part of dart_store;

// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

///
/// Abstract class, which provides default store implementation.
/// This provides an event driven development.
/// Futures are avoided to reduce cluttering in code
///
abstract class Store<T extends Model> extends EventEmitter {
  /// Incremented whenever we call suspendEvent. Decremented when resume events are called.
  int _suspendEventCount = 0;

  /// Incremented whenever we call begintransaction. Decremented when resume events are called.
  int _transactionCount = 0;

  /// Configuration for store.
  final dynamic config;

  /// Storage associated with store.
  Storage _storage;

  /// Does store supports event queueing?
  bool _supportsQueueing = false;

  /// Name of the model associated with this store.
  String _modelName = "";

  /// Default contsructor for the base store, this is invoked from derived class.
  /// A valid config can have the following format
  ///
  ///   {
  ///     "storage" : storage instance. // This could be file storage, firebase, mongodb, sqlite db etc. which is derived from [Storage] class
  ///     "cached"  : bool // Explains whether the store need to cache records in memory.
  ///     "supports_queuing"  : Whether event queueing is supported. Not implemented in this version.
  ///     "modelName" : String  // Name of the model the store holds reference to.
  ///     "filters" : List<dynamic> // Not supported initial version.
  ///     "sorters" : List<dynamic> // Not supported initial version.
  ///   }
  ///
  /// A filter take the following form
  ///   * A FilterCallback function
  ///   * A config which takes the following form.
  ///   {
  ///     property: fieldName,
  ///     value: fieldValue,
  ///     exactMatch: true,
  ///     rule  : beginswith|endswith|contains
  ///     caseSensitive: true
  ///   }
  ///
  /// A sorter can have the following form
  ///   * A comparer function
  ///   * A config which takes the following form
  ///   {
  ///     property : fieldName,
  ///     direction : asc|desc
  ///     caseSensitive: true|false
  ///   }
  ///
  ///

  Store(this.config) {
    // Parse configuration received.
    this._parseConfig();
  }

  void _parseConfig() {
    // Check if config is a valid configuration.
    if (null != config) {
      // Perform config validation.
      if (config is Map<String, dynamic>) {
        Map<String, dynamic> data = config as Map<String, dynamic>;
        data.forEach((str, val) {
          switch (str) {
            case "storage":
              this._storage = val as Storage;
              break;
            case "supports_queuing":
              this._supportsQueueing = val as bool;
              break;
            case "modelName":
              this._modelName = val as String;
              break;
          }
        });
      }
      parseConfigInternal(); // Call the derived class method so that it can implement the service.

      if (this.modelName == null || this.modelName.isEmpty) {
        throw new ArgumentError.notNull(this.modelName);
      }
    } // null != config;
  }

  @protected
  void parseConfigInternal();

  // Check storage and make sure that the underlying db is open.
  Future<bool> checkStorage() {
    return new Future(() async {
      if (storage != null && false == storage.isOpen) {
        try {
          storage.open((status, data) {
            return status == true;
          });
        } catch (ex) {
          emit("error", this,
              new CollectionError("load", "Failed to load data.", null));
          return false;
        }
      } else {
        return true;
      }
    });
  }

  /// API to begin a transaction.
  void beginTransaction() {
    ++_transactionCount;
  }

  /// API to end a transaction.
  void endTransaction() {
    --_transactionCount;
    if (_transactionCount < 0) {
      _transactionCount = 0;
    }
  }

  void suspendEvents() {
    ++this._suspendEventCount;
  }

  void resumeEvents() {
    --this._suspendEventCount;
    if (this._suspendEventCount <= 0) {
      this._suspendEventCount = 0;
      emit("refresh", this);
    }
  }

  /// Emit event if store is not suspended.
  /// Events are not queued.
  @override
  void emit(String event, [Object sender, Object data]) {
    if (this.suspended) {
      return;
    }
    super.emit(event, sender, data);
  }

  ///
  /// Load records to store.
  ///
  void load() {
    try {
      performLoad((data, error) {
        sortInternal();
        filterInternal();
        if (data != null) {
          emit("load", this, data);
        } else {
          emit("error", this,
              new CollectionError("load", "Failed to load data", error));
        }
      });
    } catch (ex) {
      emit("error", this,
          new CollectionError("load", "Failed to load data", null));
      return; // Load failed for some reason, return empty list.
    }
  }

  Future loadAsync() {
    return new Future(() {
      return this.load();
    });
  }

  /// API to add a record.
  /// Record will be added to the store records cache and filtered and sorted based on the parameters.
  void add(Model record) {
    performAdd(record, (data, error) {
      if ((data as int) > 0) {
        sortInternal();
        filterInternal();
        emit("add", this, record);
      } else {
        emit("error", this,
            new CollectionError("add", "Failed to add record", record));
      }
    });
  }

  /// Async API for add.
  Future addAsync(Model record) {
    return new Future(() {
      return add(record);
    });
  }

  /// Remove record from store.
  /// This removes record from database, then from store.
  void remove(Model record) {
    performRemove(record, (data, error) {
      if ((data as int) > 0) {
        emit("remove", this, record);
      } else {
        emit("error", this,
            new CollectionError("remove", "Failed to remove record.", record));
      }
    });
  }

  /// Async API for remove.
  Future removeAsync(Model record) {
    return new Future(() {
      return remove(record);
    });
  }

  /// Remove all records from store.
  void removeAll() {
    performRemoveAll((result, error) {
      if ((result as int) > 0) {
        emit("removeall", this);
      } else {
        emit(
            "error",
            this,
            new CollectionError(
                "removeall", "Failed to remove all records.", null));
      }
    });
  }

  ///Async API for removeAll
  Future removeAllAsync() {
    return new Future(() {
      return removeAll();
    });
  }

  /// Update a record to store.
  void update(Model record) {
    performUpdate(record, (result, error) {
      if ((result as int) > 0) {
        sortInternal();
        filterInternal();
        emit("update", this, record);
      } else {
        emit("error", this,
            new CollectionError("update", "Failed to update data", record));
      }
    });
  }

  /// Async API for update.
  Future updateAsync(Model record) {
    return new Future(() {
      return update(record);
    });
  }

  /// Returns a future.
  /// Caller can listen on the return value or can wait on the commit/error event.
  void commit() {
    performCommit((result, error) {
      if ((result as int) > 0) {
        emit("commit", this);
      } else {
        emit(
            "error",
            this,
            new CollectionError(
                "commit", "Failed to commit record to store.", null));
      }
    });
  }

  /// Async API for commit.
  Future commitAsync() {
    return new Future(() {
      return commit();
    });
  }

  Future<List<Model>> getRecordsAsync();

  List<Model> getRecords();

  @protected
  void sortInternal();
  @protected
  void filterInternal();

  void filter(
      [dynamic config,
      bool fireEvent = true,
      bool force = false,
      dynamic data = null]);

  void sort([dynamic config, bool fireEvent = true, bool force = false]);

  @protected
  void performAdd(Model record, CollectionOperationCallback callback);

  @protected
  void performRemove(Model record, CollectionOperationCallback callback);

  @protected
  void performRemoveAll(CollectionOperationCallback callback);

  @protected
  void performUpdate(Model record, CollectionOperationCallback callback);

  @protected
  void performLoad(CollectionOperationCallback callback);

  @protected
  void performCommit(CollectionOperationCallback callback);

  bool get transactionInProgress => this._transactionCount > 0;
  bool get suspended => this._suspendEventCount > 0;
  bool get queueingEnabled => this._supportsQueueing;
  String get modelName => this._modelName;
  Storage get storage => this._storage;
  int get recordCount;
  bool get isLoaded;
  bool get isFiltered;
  bool get isSorted;
}
