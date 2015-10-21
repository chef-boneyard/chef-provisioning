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
  
# Release Process

This release process applies to all chef-provisioning(-*) projects, but each project may have additional requirements.

1. Perform a Github diff between master and the last released version.  Determine whether included PRs justify a patch, minor or major version release.
2. Check out the master branch of the project being prepared for release.
3. Branch into a release-branch of the form `150_release_prep`.
4. Modify the `version.rb` file to specify the version for releasing.
5. Update the changelog to include what is being released.
  1. For these projects we use the [github changelog generator](https://github.com/skywinder/github-changelog-generator).  Install that gem if you don't have it yet.
  2. Run `github_changelog_generator -t <token> --future-release <version to release> --enhancement-labels "enhancement,Enhancement,New Feature" --bug-labels "bug,Bug,Improvement" <github project> --exclude-labels "Exclude From Changelog"`
  3. For example, if we are releasing version `1.5.0` of `chef_provisioning` the command would look like `github_changelog_generator -t 123 --future-release 1.5.0 --enhancement-labels "enhancement,Enhancement,New Feature" --bug-labels "bug,Bug,Improvement" chef/chef_provisioning --exclude-labels "Exclude From Changelog"`
  4. This will poll Github for issues and PRs to format into the changelog, then it will automatically update the changelog.
6. Parse the changelog and look for any issues/PRs that do not need to be included.  These should be tagged with the `Exclude From Changelog` tag in github.  Examples of PRs to exclude are ones that only modify the README in a trivial way.
7. `git commit` the `version.rb` and `CHANGELOG.md` changes to the branch and setup a PR for them.  Allow the PR to run any automated tests and review the CHANGELOG for accuracy.  Tag this PR with the `Exclude From Changelog` tag so it doesn't appear in the changelog for the _next_release.
8. Merge the PR to master after review.
9. Switch your local copy to the master branch and `git pull` to pull in the release preperation changes.
9. Run `rake release` on the master branch.
