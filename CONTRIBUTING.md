# Contributing to Chef Provisioning

## Resource/Provider Acceptance Criteria

There is a common set of acceptance criteria for all Chef Provisioning resources.
This is the minimum set of acceptance criteria - individual projects may expand
these.

In order to be complete, resources in this library must have the following properties:
1. The resource must have fully functional `:create` and `:destroy` actions.
  1. If the object specified by the resource already exists, and the `:create` action is called, then the `:create` action must update all available attributes for the specified object.
  1. If the attributes cannot be updated then the `:create` action must function as a `:create_if_missing`.
1. Each resource must have a full suite of tests.
  1. Tests must validate `:create` and `:destroy` actions.
  1. Tests must validate that all update-able attribute can be updated on a subsequent `:create` action.
  1. Tests may assume that if the SDK does not return an error, then the call was successful.
1. The tests must run in a CI system.
1. Reference documentation must exist on [docs.chef.io](http://docs.chef.io/provisioning.html) for the resource. The documentation must qualify any caveats / specialties about the resource and defines all available attributes & actions. The documentation must include a real world code example.
  1. An example of a caveat is that AWS Internet Gateways cannot be updated once created, they must be destroyed and recreated.
  1. All examples must be functional.  A user should be able to copy/paste the code example into a program and see it work.
