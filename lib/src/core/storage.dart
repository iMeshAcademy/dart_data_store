part of dart_store;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

/// DB callback for the database operation status.
typedef void DbCallback(bool status, dynamic data);

/// Empty callback for void operations.
typedef void EmptyCallback();

/// An abstract storage class, which helps in loading/saving to db.
/// This can be a mongo db, sqlite db or a file storage.
abstract class Storage extends EventEmitter {
  /// Config for the storage.
  /// This config is not defined and shall be provided based on the implementation.
  final dynamic config;

  /// Default contstructor.
  Storage(this.config);

  /// Open the storage / db.
  /// Usually called by Store.
  void open(DbCallback callback);

  /// Close the storage or db.
  /// Usully called by Store.
  void close(DbCallback callback);

  /// Get the storage handle.
  /// A File or FileEntry in case of File storage.
  /// An instance to DB in case of MongoDB or other databases.
  dynamic get handle;

  /// Flag to identify whether the storage is opened.
  /// Implementation specific.
  bool get isOpen;
}
