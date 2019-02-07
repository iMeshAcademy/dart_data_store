part of dart_store;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

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

  /// Detach stores from the cache. This is usually called when we unload the application or never called.
  void detach(String storeName) {
    this._stores.remove(storeName);
  }

  /// Clear all stores from the cache. Ideally, should  never be called.
  void clear() {
    this._stores.clear();
  }

  Store getByModel(String modelName) {
    return this
        ._stores
        .values
        .firstWhere((item) => item.modelName == modelName);
  }

  /// Get the store using the model name.
  Store get(String storeName) =>
      this._stores.containsKey(storeName) ? this._stores[storeName] : null;
}
