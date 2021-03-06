# 0.2.3
- Addressed analyzer warnings. 
# 0.2.2
- Addressed analyzer warnings and maintenance hint in pub.
# 0.2.1
- Provided example and test cases for the store.
- Readme updated.
# 0.2.0
- Updated store to provide sync and asyn APIs to retrieve records.
# 0.1.9
- Segregated the sortable and filterable framework code for data_store.
# 0.1.8
- Updated framework to accept filter parameters.
- This is provided as an extension to the existing API.
- A new datastructure shall be introduced in future to accomodate any future filter mechanism.

# 0.1.7
- Provided support for disable sort/disable filter.
- Faster sort is enabled with optimized sorters.
# 0.1.6
- Optimized performance of the framework.
- Updated memory store to improve sort performance as it uses sorted collection, which automatically performs sorting.
- 
# 0.1.5
- Issues with filter operation. Added support for forceFilter, which will enable user to perform force filtering the store, even if the store is already filterd - Scenario where an update causes the record to be filtered out would be an example.
# 0.1.4
- Setting/getting key independent of fields. 
- Key would be set or get whether it is defined in fields for the model.
- Updated the parser to use new API to set value to model.
- Updated model and store generators to accept model/store name respectively.
- Store generator map should contain config for store generation also, this is a mandatory field. Refer example section for how to pass config to store while creating it.

# 0.1.3
- Setting up ID/Key value was changing the id field.
- Provided a setValue API to set values in the value configuration.
- idField is made static, so this can be accessed throug the Class name.
- performSanity API is provided to enable sanity check when setting values. This API shall be implemented by derived class.
# 0.1.3
- Provided values => a getter to retrieve the values from model.
# 0.1.2
- Updated DI mechanism for the storage and other modules.

# 0.1.1
- Provided support for Sortable and Filterable.

# 0.1.0
- Added example.dart, different examples. Stable version.

# 0.0.9

- Added CHANGELOG.md

# 0.0.8

First reviewed version.