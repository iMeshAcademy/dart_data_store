part of dart_store;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Create model using model information and Json instance provided.
class ModelFactory {
  /// Static instance of singleton instance.
  static ModelFactory _factory = new ModelFactory._();

  /// Model generators, coule be used at runtime by the store.
  Map<String, ModelGeneratorFunction> _modelGenerator =
      new Map<String, ModelGeneratorFunction>();

  /// Private constructor.
  ModelFactory._();

  /// Singleton instance.
  static ModelFactory get instance => _factory;

  /// Attach model generator function against model name.
  void attach(String modelName, ModelGeneratorFunction function) {
    this._modelGenerator[modelName] = function;
  }

  /// Detach model generator function.
  void detach(String modelName) {
    this._modelGenerator.remove(modelName);
  }

  /// Create a model from the configurator
  Model createModel(String modelName, Map<String, Object> configs) {
    return this._modelGenerator[modelName](configs) ?? null;
  }
}
