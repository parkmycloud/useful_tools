# IAM Policies for use in an IAM Role for ParkMyCloud Cross-Account Access
----

Here are some example policies you can use to grant **ParkMyCloud** the minimum permissions necessary to manage your AWS resources.

## PMCRecommendedAWSPolicy.json
Provides the core functionality for the ParkMyCloud service.

## PMCRecommendedAWSPolicy-with-tagging.json
Same permissions as the base recommended policy, but requires a tag on certain resources in order to allow start/stop action.  Good for AWS accounts that contain a mixture of  Dev/Test/Production resources.

## PMCRecommendedAWSPolicy-simple.json
Most of the core functionality of the recommended policy, but laid out in the simplest fashion possible.

## For more information...
See our [User Guide](https://parkmycloud.atlassian.net/wiki/x/BYCMAg) for a more detailed description of these various policies.
