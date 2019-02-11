import 'package:dart_store/dart_store.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
// Initialize framework using configuration.
    Config().initialize(
        {"stores": App.storeConfig, "models": App.modelConfiguration});
  });

  validateStores();
  validateModelCreation();
  validateBulkAddition();
  validateFilter();
  validateSort();
}

void validateStores() {
  group("store", () {
    test("Store generation - Option 1 - By storeName", () {
// Get a store -> Different ways to do that. Using store name.
      UserStore store = StoreFactory().get("UserStore");
      expect(store != null, true);
    });

    test("Store Generation - Option 2 - By model name", () {
      // Retrieve store using the ModelName.
      UserStore store = StoreFactory().getByModel("UserModel");
      expect(store.modelName, "UserModel");
    });
  });
}

void validateModelCreation() {
  group("Models", () {
    test("Model Creation by using [ModelFactory]", () {
      var modelConfig = {
        "__id__": "UniqueKeyForMichael",
        "FirstName": "Michael",
        "LastName": "Owen",
        "Age": 30,
        "Gender": "Male"
      };

      UserModel model =
          ModelFactory.instance.createModel("UserModel", modelConfig);
      expect(model != null, true);
      expect(model.getValue("FirstName"), "Michael");
      expect(model.key, "UniqueKeyForMichael");
    });

    test("Model Creation by using instance and setters.", () {
      UserModel model = ModelFactory.instance.createModel("UserModel", null);
      model.setValue("FirstName", "Michael");
      model.setValue("LastName", "Owen");
      model.setValue("Age", 34);
      model.setValue("Gender", "Male");
      model.key = "UniqueKeyForMichael_1";

      expect(model.getValue("Age"), 34);
      expect(model.key, "UniqueKeyForMichael_1");
    });
  });
}

void validateBulkAddition() {
  group("Add", () {
    test("add bulk", () {
      UserStore store = StoreFactory().get("UserStore");

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
      expect(store.recordCount, 100);
    });
  });
}

void validateFilter() {
  group("Filter", () {
    test("Validate filter method", () {
      UserStore store = StoreFactory().get("UserStore");

      var filterConfig = {
        "property": "__id__",
      };
      store.on("filter", store, (ev, ct) {
        expect(ev.eventData != null, true);
        print(ev.eventData);
        expect((ev.eventData as List<Model>)[0].key, "UserMoadel_40");
      });
      store.filter(filterConfig, true, false, "UserMoadel_40");
      store.removeAllByEvent("filter");

      store.clearFilters();
      store.clearSorters();
      expect(store.recordCount, 100);
    });
  });
}

void validateSort() {
  group("Sort", () {
    test("Sort logic", () {
      UserStore store = StoreFactory().get("UserStore");

      var sorter = {
        "property": Model.idField, // Sorter property name ( Case-sensitive)
        "direction": "desc",
        "comparer": stringComparer,
        "name": "sortId", // A name for the sorter.
        "enabled": true // Make it to true to enable sorting using the sorter.
      };
      store.sort(sorter);

      expect(store.recordCount, 100);
      expect(store.records[0].key, "UserMoadel_99");
      store.clearSorters();
      expect(store.records[0].key, "UserMoadel_99");
    });
  });
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
