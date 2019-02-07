part of dart_store;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Callback function for store generator.
typedef Store StoreGeneratorFunction(
    String storeName, Map<String, Object> config);

/// Callback function for model generator.
typedef Model ModelGeneratorFunction(
    String modelName, Map<String, Object> config);

///
/// Default configuration class for framework.
/// User shall pass the custom configuration in this function in-order to get it working.
/// Configurations for store and models shall be passed to this function.
///
class Config {
  /// Model generator for the application. This is parsed from the config provided.
  final Map<String, ModelGeneratorFunction> _modelGenerators =
      Map<String, ModelGeneratorFunction>();

  /// Store generators for the application. Parsed from the config provided.
  final Map<String, StoreGeneratorFunction> _storeGenerators =
      Map<String, StoreGeneratorFunction>();

  /// A static instance, which provides singleton functionality.
  static final Config _instance = new Config._();
  Config._();

  /// Factory method for the class. Returns singleton always.
  factory Config() {
    return _instance;
  }

  /// Initialize stores and models as per config.
  /// StoreFactory and ModelFactory shall be updated after this function is called.
  void initialize(dynamic config) {
    if (config != null) {
      try {
        // Typecast to json object.
        var jsonData = config as Map<String, Map<String, Map<String, dynamic>>>;

        /// Private api for parsing store information
        _parseStores(storeCfgs) {
          if (null != storeCfgs) {
            Map<String, Map<String, dynamic>> cfgs =
                storeCfgs as Map<String, Map<String, dynamic>>;

            cfgs.forEach((str, val) {
              StoreGeneratorFunction fn =
                  val["generator"] as StoreGeneratorFunction;
              this._storeGenerators[str] = fn;
              // Attach to StoreFactory. The generator should be a valid callback function.
              StoreFactory().attach(str, fn(str, val["config"]));
            });
          }
        }

        /// Private API for parsing model information.
        _parseModels(modelCfgs) {
          if (null != modelCfgs) {
            Map<String, Map<String, dynamic>> cfgs =
                modelCfgs as Map<String, Map<String, dynamic>>;

            cfgs.forEach((str, val) {
              ModelGeneratorFunction fn =
                  val["generator"] as ModelGeneratorFunction;
              this._modelGenerators[str] = fn;

              // Attach to ModelFactory. The fn should be a valid function.
              ModelFactory.instance.attach(str, fn);
            });
          }
        }

        if (null != jsonData) {
          jsonData.forEach((key, val) {
            switch (key) {
              case "stores":
                _parseStores(val);
                break;
              case "models":
                _parseModels(val);
                break;
            }
          });
        }
      } catch (ex) {
        print(ex);
      }
    }
  }
}
