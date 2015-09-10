# Contributing to Chef Provisioning

## Resource/Provider Acceptance Criteria

There is a common set of acceptance criteria for all Chef Provisioning resources.
This is the minimum set of acceptance criteria - individual projects may expand
these.

In order to be complete, resources in this library must have the following properties:

1. The resource must have fully functional `:create` and `:destroy` actions.
  1. If the object specified by the resource already exists, and the `:create` action is called, then the `:create` action must update all available attributes for the specified object.
  2. If the attributes cannot be updated then the `:create` action must function as a `:create_if_missing`.
2. Each resource must have a full suite of tests.
  1. Tests must validate `:create` and `:destroy` actions.
  2. Tests must validate that all update-able attribute can be updated on a subsequent `:create` action.
  3. Tests may assume that if the SDK does not return an error, then the call was successful.
3. The tests must run in a CI system.
4. Reference documentation must exist on [docs.chef.io](http://docs.chef.io/provisioning.html) for the resource. The documentation must qualify any caveats / specialties about the resource and defines all available attributes & actions. The documentation must include a real world code example.
  1. An example of a caveat is that AWS Internet Gateways cannot be updated once created, they must be destroyed and recreated.
  2. All examples must be functional.  A user should be able to copy/paste the code example into a program and see it work.
5.  If an attribute is not specified on a resource, and update should _not_ modify that attribute on the object.  For example, leaving the `routes` attribute off a `aws_route_table` resource should not clear all existing routes.  It should leave them alone.
  1.  To clear a attribute you should specify an empty array/hash for attributes that accept multiple values.
  2.  Starting in Chef 12.5 attributes can have the `nil` value set on them.  This will signify that the attribute should be cleared or reset to the default.  EG, setting `description nil` will clear the current description.

## Proposed Acceptance Criteria

1.  Provisioning recipes need to be paramaterized.  This is often done by specifying modifying attributes via environments or roles.  It can also be searched from a 3rd party service, such as a CMDB.  All resources should adhere to this principal.
  1.  This effectively means a user who models an object as a hash or struct should be able to pass that to the resource and have the resource converge it.  If it is a hash, the resource should handle strings vs symbols vs Mashes correctly.
  2.  It could also mean that we add a criteria saying a resource should be able to explode the elements of a hash into the attributes of the resource before converging it.  IE, an `options` hash would accept a JSON object and the resource would use this to populate the `description`, `count` and `style` attributes on the resource.
