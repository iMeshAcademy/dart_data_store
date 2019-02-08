part of dart_store;

typedef int SortComparerCallback<T extends Model>(T record1, T record2);

mixin Sortable<T extends Model> {
  List<dynamic> _sorters = List<dynamic>();
  bool _sortSuspended = false;

  List<dynamic> get sorters => this._sorters;

  @protected
  set sorters(List<dynamic> value) => this._sorters = value;

  bool get hasSorters => this._sorters.isNotEmpty;

  void onSorted();

  /// Sort failed.
  void onSortFailed();

  void supendSort() {
    this._sortSuspended = true;
  }

  void resumeSort() {
    this._sortSuspended = false;
  }

  void removeSorter(dynamic sorter) {
    throw new UnsupportedError("This API is not supported in this version.");
  }

  void clearSorters() {
    throw new UnsupportedError("This API is not supported in this version.");
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
  void sortList(List<T> recs, DatabaseOperationCallback callback) {
    // Sorting is suspended, return.
    if (this._sortSuspended ||
        this.hasSorters == false ||
        null == recs ||
        recs.isEmpty) {
      if (null != callback) callback(null, "Sort Failed");
      return;
    }

    for (var i = 0; i < this.sorters.length; i++) {}

    List<Function> fns = List<Function>();

    this.sorters.forEach((sorter) {
      Function sort;
      bool caseSensitive = false;
      String direction = "";
      Function comparer;
      if (sorter is SortComparerCallback) {
        sort = sorter;
      } else if (sorter is Map<String, dynamic>) {
        caseSensitive = sorter['caseSensitive'] ?? false;
        direction = sorter["direction"] ?? "asc";

        comparer = sorter["comparer"];

        sort = (Model a, Model b) {
          dynamic val1 = a.getValue(sorter["property"]);
          dynamic val2 = b.getValue(sorter["property"]);

          if (caseSensitive && val1 is String) {
            val1 = (val1 as String).toLowerCase();
            val2 = (val2 as String).toLowerCase();
          }

          var sortValue = comparer != null
              ? comparer(val1, val2)
              : val1 > val2 ? 1 : val1 == val2 ? 0 : -1;

          if (direction != "asc") {
            sortValue *= -1;
          }

          return sortValue;
        };
      }
      fns.add(sort);
    });

    recs.sort((a, b) {
      int sort = 0;

      for (var i = 0; i < fns.length; i++) {
        sort = fns[i](a, b);
        if (sort != 0) {
          break;
        }
      }
      // for (var i = 0; i < this.sorters.length; i++) {
      //   var sorter = sorters[i];

      //   if (sorter is SortComparerCallback) {
      //     sort = sorter(a, b);
      //   } else if (sorter is Map<String, dynamic>) {
      //     bool caseSensitive = sorter['caseSensitive'] ?? false;
      //     String direction = sorter["direction"] ?? "asc";
      //     dynamic val1 = a.getValue(sorter["property"]);
      //     dynamic val2 = b.getValue(sorter["property"]);

      //     Function comparer = sorter["comparer"];
      //     if (caseSensitive && val1 is String) {
      //       val1 = (val1 as String).toLowerCase();
      //       val2 = (val2 as String).toLowerCase();
      //     }
      //     sort = comparer != null
      //         ? comparer(val1, val2)
      //         : val1 > val2 ? 1 : val1 == val2 ? 0 : -1;

      //     if (direction != "asc") {
      //       sort *= -1;
      //     }
      //   }

      //   if (sort != 0) {
      //     break;
      //   }
      // }

      return sort;
    });

    if (null != callback) {
      callback(recs, null);
    }
  }

  /// This function provide sorting support to the store.
  /// Sorter can be a sort configuration, understood by the implementation or a callback function.
  /// If callback function is specified, that function shall be used as a comparer by the implementer.
  @protected
  void applySorter(List<T> records, dynamic sorter,
      [bool fireEvent = true, bool force = false]) {
    if (null == records || records.isEmpty) {
      this.onSortFailed();
      return; // Either already sorted, or no need to sort the list.
    }

    if (null != sorter && false == this._sorters.contains(sorter)) {
      // Add  new sorter to the list.
      this._sorters.add(sorter);
    }

    // Perform sort operation.
    sortList(records, (data, error) {
      if (error != null) {
        onSortFailed();
      } else {
        // Flag sorted to true.
        if (fireEvent) onSorted(); // Fire sort event.
      }
    });
  }
}
