import 'package:dart_store/dart_store.dart';
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

main() {
// Initialize framework using configuration.
  Config().initialize(
      {"stores": App.storeConfig, "models": App.modelConfiguration});

  // Get a store -> Different ways to do that. Using store name.
  UserStore store = StoreFactory().get("UserStore");
  if (null != store) {
    print("Valid store configuration - $store");
  }

  assert(store != null); // Check if store is valid.

  // Retrieve store using the ModelName.
  store = StoreFactory().getByModel("UserModel");

  if (null != store) {
    print("Valid store configuration - $store");
  }

  assert(store != null); // Check if store is valid.

  // Different ways to create models.

  // Option 1 :

  var modelConfig = {
    "__id__": "UniqueKeyForMichael",
    "FirstName": "Michael",
    "LastName": "Owen",
    "Age": 30,
    "Gender": "Male"
  };

  UserModel model = ModelFactory.instance.createModel("UserModel", modelConfig);
  assert(model != null);
  assert(model.getValue("FirstName") == "Michael");
  assert(model.key == "UniqueKeyForMichael");

  // Option 2
  model = ModelFactory.instance.createModel("UserModel", null);
  model.setValue("FirstName", "Michael");
  model.setValue("LastName", "Owen");
  model.setValue("Age", 34);
  model.setValue("Gender", "Male");
  model.key = "UniqueKeyForMichael_1";

  assert(model.getValue("Age") == 34);
  assert(model.key == "UniqueKeyForMichael_1");

  // Store operation
  // Store can't be loaded from outside.
  // If store needed to be loaded form outside the class, then provide a storage implementation
  // and implement the load API in the [Storage] class.

  // 1. Add

  store.suspendEvents();
  store.suspendFilter();
  store.supendSort();

  // The above steps make sure that store won't fire events or perform sort or filter
  // while data is being added in bulk.
  // If needed, an addBulk API can be introduced in future.

  for (var i = 0; i < 100; i++) {
    var modelCfg = {
      "${Model.idField}": "UserMoadel_$i",
      "FirstName": "UserName-$i",
      "LastName": "User Last Name - $i",
      "Age": i % 50 + 10,
      "Gender": i % 3 == 0 ? "F" : "M"
    };

    store.add(ModelFactory.instance.createModel("UserModel", modelCfg));
  }

  store.resumeSort();
  store.resumeFilters();
  store.sort();
  store.filter();
  store.resumeEvents();

  // Additionally fire event's if you need one.
  assert(store.recordCount == 100);
  // Filter name by id

  var filterConfig = {
    "property": "__id__",
  };
  store.on("filter", store, (ev, ct) {
    assert(ev.eventData != null);
    if (null != ev.eventData) {
      print(ev.eventData);
      assert((ev.eventData as List<Model>)[0].key == "UserMoadel_40");
    } else {
      print("No user data received");
    }
  });
  store.filter(filterConfig, true, false, "UserMoadel_40");
  store.removeAllByEvent("filter");

  store.clearFilters();
  store.clearSorters();
  assert(store.recordCount == 100);

  var sorter = {
    "property": Model.idField, // Sorter property name ( Case-sensitive)
    "direction": "desc",
    "comparer": stringComparer,
    "name": "sortId", // A name for the sorter.
    "enabled": true // Make it to true to enable sorting using the sorter.
  };
  store.sort(sorter);

  assert(store.recordCount == 100);
  assert(store.records[0].key == "UserMoadel_99");
  store.clearSorters();
}

class UserModel extends Model {
  UserModel(Map<String, dynamic> config)
      : super(modelName: "UserModel", config: config);

  bool _isModified = false;
  static List<String> UserFields = ["FirstName", "LastName", "Age", "Gender"];
  @override
  List<String> get fields => UserFields;

  @override
  bool get isModified => this._isModified;

  @override
  void setValue(String key, value) {
    this._isModified = true;
    super.setValue(key, value);
  }

  @override
  bool performSanity(String key, value) {
    switch (key) {
      case Model.idField:
      case "FirstName":
      case "Gender":
        return (value == null || (value is String) == false || value.isEmpty)
            ? false
            : true;
      case "Age":
        return value is int ? true : false;
      case "LastName":
        return true; // Last name is not mandatory.
    }
    return false;
  }

  @override
  Map<String, Object> toJson() {
    return config;
  }
}

class UserStore extends MemoryStore {
  UserStore(config) : super(config);
}

int stringComparer(String a, String b) {
  if (a == null) {
    return -1;
  }
  if (b == null) {
    return 1;
  }
  return a.compareTo(b);
}

int ageComparer(double a, double b) {
  return a.compareTo(b);
}

class App {
  static const UserFilters = [
    /*{   // Sample format
      // "property": "FirstName",
      // "value": "itemName",
      // "exactMatch": true,
      // "rule": "beginswith",
      // "caseSensitive": true,
      // "name": "byItemName",  // Give a name to the filter, so that it can be easily retrieved or accessed later.
      // "cached": false  // Identifies the filter as temporary or permanent. Temporary filters could get cleaned by clear temp filter call.
    },
    // inventoryFilteryByCost,
    {
      // "property": "Cost",
      // "value": 30,
    }, */
  ];

  static final userSorters = [
    {
      "property": "FirstName", // Sorter property name ( Case-sensitive)
      "direction": "asc",
      "comparer": stringComparer,
      "name": "sortByName", // A name for the sorter.
      "enabled": true // Make it to true to enable sorting using the sorter.
    },
    {
      "property": "Age",
      "direction": "desc",
      "comparer": ageComparer,
      "name": "sortByCost", // Name for the sorer.
      "enabled": false
    },
  ];

  static bool userFilteryByAge(Model model, dynamic age) {
    return model.getValue("Age") > age ??
        35.0; // Use age otherwise,use 35 ( Just some arbitrary number )
  }

  /// Sample configuration for stores
  static Map<String, Map<String, dynamic>> storeConfig = {
    "UserStore": {
      "generator": storeGenerator,
      "config": {
        "storage":
            null, // This could be file storage, firebase, mongodb, sqlite db etc. which is derived from [Storage] class
        "cached":
            true, // Explains whether the store need to cache records in memory.
        "supports_queuing":
            false, //Whether event queueing is supported. Not implemented in this version.
        "modelName":
            "UserModel", // Name of the model the store holds reference to.
        "filters": UserFilters,
        "sorters": userSorters
      }
    }
  };

  /// Sample configuration for models.
  static Map<String, Map<String, dynamic>> modelConfiguration = {
    "UserModel": {"generator": modelGenerator}
  };

  static Store storeGenerator(String storeName, dynamic config) {
    Store str;
    switch (storeName) {
      case "UserStore":
        str = new UserStore(config);
        break;
    }

    return str;
  }

  static Model modelGenerator(String modelName, dynamic config) {
    Model m;
    switch (modelName) {
      case "UserModel":
        m = new UserModel(config);
    }
    return m;
  }
}
