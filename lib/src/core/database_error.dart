part of dart_store;

class DatabaseError {
  final String operation;
  final String reason;
  final Object data;

  DatabaseError(this.operation, this.reason, this.data);
}
