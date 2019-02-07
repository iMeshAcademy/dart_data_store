part of dart_store;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void DbCallback(bool status, dynamic data);
typedef void EmptyCallback();

abstract class Storage extends EventEmitter {
  final dynamic config;
  Storage(this.config);

  void open(DbCallback callback);
  void close(DbCallback callback);
  dynamic get handle;
  bool get isOpen;
}
