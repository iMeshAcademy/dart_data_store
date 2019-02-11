part of dart_store;

// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

/// Factory for creating different stores with different configurations.
/// This shall be invoked prior to using stores in application.
///
/// Valid store configuration, which needed to be passed in the Config.initialize function is as follows.
///
/**  {
    "UserStore": {   //   [UserStore] is name of the store defined in the application.
      "generator": storeGenerator,  // [storeGenerator] is a generator function which create store for the defined application.
      "config": {   // Configuration for the store.
        "storage":  // If any storage instance of [Storage] is needed, then provide in this. Refer [JsonStore] in the example section for more details.
            null, // This could be file storage, firebase, mongodb, sqlite db etc. which is derived from [Storage] class
        "cached":
            true, // Explains whether the store need to cache records in memory.
        "supports_queuing":
            false, //Whether event queueing is supported. Not implemented in this version.
        "modelName":
            "UserModel", // Name of the model the store holds references of.
        "filters": UserFilters,   // List of filtes needed for this store. Refer [Store] for more details.
        "sorters": userSorters  // List of sorters for the store. Refer [Store] for details.
      }
    }
  } */
///
/// [UserFilters] in the above sample code could take the following format.
/**   
  static const UserFilters = [
    { 
      "property": "FirstName",
      "value": "itemName",
       "exactMatch": true,
       "rule": "beginswith",
       "caseSensitive": true,
       "name": "byItemName",  // Give a name to the filter, so that it can be easily retrieved or accessed later.
       "cached": false  // Identifies the filter as temporary or permanent. Temporary filters could get cleaned by clear temp filter call.
    },
    // :: Filter users by age. No regular expressions supported in this version.
    {
       "property": "Age",
       "value": 30,         /* What should be the value for the filter function. */
       "name": "byAge",
    }, 
  ];

  */
///
///

class StoreFactory {
  /// Static instance for StoreFactory,
  static final StoreFactory _instance = new StoreFactory._internal();

  // Stores are created for individual models.
  // These store names are pulled from config.
  // First item in the store entry is the model name,
  // for which store needed to be created.
  Map<String, Store> _stores = Map<String, Store>();

  factory StoreFactory() {
    return _instance;
  }

  /// Private constructor.
  StoreFactory._internal();

  /// Attach store to the cache.
  void attach(String storeName, Store store) {
    if (_stores.containsKey(storeName)) {
      throw new Exception("A store is already associated with $storeName");
    }
    _stores[storeName] = store;
  }

  /// Detach stores from the cache. This is usually called when we unload the application or it just never get called.
  void detach(String storeName) {
    this._stores.remove(storeName);
  }

  /// Clear all stores from the cache. Ideally, should  never be called.
  void clear() {
    this._stores.clear();
  }

  /// Retrive the store by model name.
  /// Make sure to have the correct model name in the store configuration.
  /// [modelName] - name of the model the store bound to. Store will contain references of this model.
  Store getByModel(String modelName) {
    return this
        ._stores
        .values
        .firstWhere((item) => item.modelName == modelName);
  }

  /// Get the store using the store name.
  /// [storeName] - name of the store defined in the application.
  /// [storeName] shall be a valid store name in the configuration.
  Store get(String storeName) =>
      this._stores.containsKey(storeName) ? this._stores[storeName] : null;
}
