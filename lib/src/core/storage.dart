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
  final dynamic config;
  Storage(this.config);

  void open(DbCallback callback);
  void close(DbCallback callback);
  dynamic get handle;
  bool get isOpen;
}
