part of dart_store;

typedef int SortComparerCallback<T extends Model>(T record1, T record2);

mixin Sortable<T extends Model> {
  List<dynamic> _sorters = List<dynamic>();
  bool _sorted = false;
  bool _suspended = false;

  List<dynamic> get sorters => this._sorters;

  @protected
  set sorters(List<dynamic> value) => this._sorters = value;

  bool get hasSorters => this._sorters.isNotEmpty;
  bool get sorted => this._sorted;

  void onSorted();
  void onSortFailed();

  /// This function provide sorting support to the store.
  /// Sorter can be a sort configuration, understood by the implementation or a callback function.
  /// If callback function is specified, that function shall be used as a comparer by the implementer.
  @protected
  void applySorter(List<T> records, dynamic sorter, [bool fireEvent = true]) {
    if (null == records) {
      return; // Either already sorted, or no need to sort the list.
    }

    if (null != sorter && false == this._sorters.contains(sorter)) {
      // Add  new sorter to the list.
      this._sorters.add(sorter);
    }

    // Perform sort operation.
    performSort(records, (data, error) {
      if (error != null) {
        this._sorted = false;
        onSortFailed();
      } else {
        // Flag sorted to true.
        this._sorted = true;
        if (fireEvent) onSorted(); // Fire sort event.
      }
    });
  }

  ///
  ///   Sort list routine. This helper perform basic sorting operation based on the sort logic.
  ///
  ///   {
  ///     property : fieldName,
  ///     direction : asc|desc
  ///     caseSensitive: true|false
  ///   }
  ///
  @protected
  void sortList(List<T> recs) {
    if (hasSorters == false || null == recs) {
      return;
    }
    recs.sort((a, b) {
      int sort = 0;
      for (var i = 0; i < this.sorters.length; i++) {
        var sorter = sorters[i];

        if (sorter is SortComparerCallback) {
          sort = sorter(a, b);
        } else if (sorter is Map<String, dynamic>) {
          bool caseSensitive = sorter['caseSensitive'] ?? false;
          String direction = sorter["direction"] ?? "asc";
          dynamic val1 = a.getValue(sorter["property"]);
          dynamic val2 = b.getValue(sorter["property"]);

          print("Val1 - $val1, val2 - $val2");
          Function comparer = sorter["comparer"];
          if (caseSensitive && val1 is String) {
            val1 = (val1 as String).toLowerCase();
            val2 = (val2 as String).toLowerCase();
          }
          sort = comparer != null
              ? comparer(val1, val2)
              : val1 > val2 ? 1 : val1 == val2 ? 0 : -1;

          if (direction != "asc") {
            sort *= -1;
          }

          print("sort after comparer - $sort");
        }

        if (sort != 0) {
          break;
        }
      }
      print("sort returnig fuction - $sort");

      return sort;
    });
  }

  ///
  ///   Perform sort operation. Sort can be done using the following configuration or by using a comparer.
  ///   {
  ///     property : fieldName,
  ///     direction : asc|desc
  ///     caseSensitive: true|false,
  ///     name  : String - a unique name for this sorter.
  ///   }
  ///
  @protected
  void performSort(List<T> records, DatabaseOperationCallback callback) {
    if (this._suspended) {
      return;
    }
    sortList(records);
    if (null != callback) {
      callback(records, null);
    }
  }

  void supendSort() {
    this._suspended = true;
  }

  void resumeSort() {
    this._suspended = false;
  }

  void removeSorter() {}

  void clearSorters() {}
}
