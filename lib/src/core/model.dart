part of dart_store;

// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Model {
  final String modelName;

  // ID field for the model. This is unique and will be used in key for the model.
  static const String idField = '__id__';
  final Map<String, dynamic> config;
  Map<String, dynamic> _values = Map<String, dynamic>();

  @protected
  bool get isModified;

  ///
  /// Constructor for the model.
  /// @modelName - String, name of the model.
  /// @config - Configuration for the model.
  /// Configuration for model. This could take the following form
  ///   {
  ///     "values"  : {
  ///                   "field1"  : "value1",
  ///                   "field2"  : "value2"
  ///                 }
  ///   }
  ///
  Model({@required this.modelName, @required this.config}) {
    parseConfig();
  }

  List<String> getFields();

  void parseConfig() {
    if (null != config && config.keys.contains("values")) {
      Map<String, dynamic> values = config["values"];
      values.forEach((str, val) {
        if (this.getFields().contains(str)) {
          if (str == idField) {
            this.key = val;
          } else {
            setValue(str, val); // Set value using the defined API.
          }
        } else {
          print("invalid field received in config");
        }
      });
    }
  }

  void save() {
    if (isModified) {
      var store = StoreFactory().get(modelName);
      if (key.length > 0) {
        store.update(this);
      } else {
        store.add(this);
      }
    }
  }

  String getIdField() => Model.idField;
  /**
   * Retrieve the unique key or id field for the model.
   */
  String get key => this._values[idField];

  /**
   * Try to set the unique ID field or key for the model.
   * It is not possible to set a different ID once the ID filed is initlaized and valid.
   */
  set key(String value) {
    if (this.values[idField].trim().length > 0) {
      return;
    }

    this.values[idField] = value;
  }

  Map<String, Object> toJson();
  Map<String, dynamic> get values => this._values;

  List<String> get fields => this.getFields();
  bool performSanity(String key, dynamic value);
  dynamic getValue(String key) => key == idField
      ? this.key
      : this._values.containsKey(key) ? this._values[key] : null;
  void setValue(String key, dynamic value) {
    if (key == idField) {
      this.key = value;
    } else if (this.fields.contains(key)) {
      if (performSanity(key, value)) {
        this._values[key] = value;
      } else {
        throw new ArgumentError(
            "Failed perform sanity check on $key with value - $value");
      }
    } else {
      throw new ArgumentError(
          "The field - $key does not exist for model $modelName");
    }
  }
}
