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
  ///
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
  ///     "name" : "nameOfFilter"
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
  ///   or the below form
  ///   {
  ///    "property": "FirstName", // Sorter property name ( Case-sensitive)
  ///    "direction": "asc",
  ///    "comparer": stringComparer,
  ///    "name": "sortByName", // A name for the sorter.
  ///    "enabled": true // Make it to true to enable sorting using the sorter.
  ///  },
  ///
  ///
  Store(this.config) {
    // Parse configuration received.
    this._parseConfig();
  }

  /// Private API for parsing store configuration.
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

  /// protected API for parsing configuration. This should be overriden by derived classes.
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

  /// Suspend store from emitting any events.
  void suspendEvents() {
    ++this._suspendEventCount;
  }

  /// Resume store to fire events.
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

  /// Load store records async.
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

  /// Abstract getter to retrieve records async.
  /// For ex. a proxy store, which downloads data from server, could implement this API, and load data async from server.
  /// Refer [MemoryStore] for a basic implementation of this API.
  Future<List<Model>> getRecordsAsync();

  /// Get the list of records in the store.
  List<Model> getRecords();

  /// Internal API to perform sorting.
  /// Implementer of this API shall provide correct sorting logic.
  ///
  /// NOTE - This API is not implemented for [MemoryStore] as memory store supports sorting by default,
  /// either when data is loaded, added or removed from collection.
  ///  If your derived stores won't support sorting by default ( or doesn't extend [ModelCollection] mixin ), then provide sorting logic here.
  ///
  @protected
  void sortInternal();

  ///
  /// Provide your store filtering logic here.
  /// Not needed if your derived store extends [ModelCollection] mixin.
  ///
  @protected
  void filterInternal();

  /// API to perform filtering operation.
  void filter(
      [dynamic config,
      bool fireEvent = true,
      bool force = false,
      dynamic data]);

  /// API to perform sorting operation.
  void sort([dynamic config, bool fireEvent = true, bool force = false]);

  /// Business logic to add record to store/database/remote database.
  @protected
  void performAdd(Model record, CollectionOperationCallback callback);

  /// Business logic to remove record from store/database/remote database.
  @protected
  void performRemove(Model record, CollectionOperationCallback callback);

  /// Business logic to remove all records from store/database/remote database.
  @protected
  void performRemoveAll(CollectionOperationCallback callback);

  /// Business logic to update record to store/database/remote database.
  @protected
  void performUpdate(Model record, CollectionOperationCallback callback);

  /// Business logic to load records to store/database/remote database.
  @protected
  void performLoad(CollectionOperationCallback callback);

  /// Business logic to commit  to store/database/remote database if it supprts transactional model.
  @protected
  void performCommit(CollectionOperationCallback callback);

  /// Getter to identify if any transaction in progress.
  bool get transactionInProgress => this._transactionCount > 0;

  /// Getter to identify if store is suspended from emitting events.
  bool get suspended => this._suspendEventCount > 0;

  /// Returns true if store supports event queueing. Used when store is [suspended]. Not supported now.
  bool get queueingEnabled => this._supportsQueueing;

  /// Return the model name associated with this store.
  String get modelName => this._modelName;

  /// Return the storage associated with the store.
  ///
  /// [storage] is an instance of [Storage] class.
  ///
  /// Valid storages can be FileStorage, Databases like MongoDb, MySQl, Firebase etc.
  ///
  /// One shall provide appropriate wrapper for the above mentioned storage.
  ///
  Storage get storage => this._storage;

  /// Retrieve count of total records in the store.
  int get recordCount;

  /// This is used to identify if store is loaded.
  bool get isLoaded;

  /// This can be used to identify the filtered state of the store.
  bool get isFiltered;

  /// This can be used to identify the sorted state of the store.
  bool get isSorted;
}
