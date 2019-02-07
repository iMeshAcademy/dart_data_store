#0.1.5
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