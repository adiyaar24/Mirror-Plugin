# Git Repository Sync Script

This script is used to synchronize Git references (such as branches or tags) from a source repository to a target repository. It supports both authenticated and anonymous modes for accessing the source repository and handles creation, updates, and deletions of Git references.

## Features
- **Anonymous Mode**: Sync without requiring authentication for the source repository.
- **Authenticated Mode**: Supports authentication for both source and target repositories using tokens.
- **Reference Management**: Handles the creation, update, and deletion of references (e.g., branches or tags) between repositories.
- **Conditional Deletion**: Allows safe deletion of references on the target repository if they are removed from the source repository, with additional checks for old SHA values.
- **Force Push Handling**: Supports handling of forced updates when fast-forwarding is not possible.

## Usage

The script expects the following environment variables to be set, which configure how the synchronization will be handled:

### Environment Variables

- `PLUGIN_ANONYMOUS`: (Optional) Set to `true` to enable anonymous mode for the source repository, where no authentication is required.
- `PLUGIN_SOURCE_TOKEN`: The access token for the source repository (required if `PLUGIN_ANONYMOUS` is not set to `true`).
- `PLUGIN_SOURCE_URL`: The HTTPS-formatted clone URL of the source repository.
- `PLUGIN_TARGET_TOKEN`: The access token for the target repository.
- `PLUGIN_TARGET_URL`: The HTTPS-formatted clone URL of the target repository.
- `PLUGIN_REFERENCE`: The full Git reference path to be synced, such as `refs/heads/main` (for branches) or `refs/tags/v1.2.3` (for tags).
- `PLUGIN_REFERENCE_SHA_OLD`: (Optional) The old SHA value of the reference before it was updated on the source repository. Used for safe syncing of changes.
- `PLUGIN_SYNC_DELETE`: (Optional) Set to `true` to sync reference deletions from the source to the target repository. If not set, deletions are skipped.

### Variables Description

| Variable Name        | Type    | Description                                                                                                                                                                                                                                 | Required |
|----------------------|---------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| `sourceToken`         | Secret  | Access token for the source repository.                                                                                                                                                                                                     | Yes      |
| `sourceURL`           | String  | The HTTPS-format clone URL of the source repository.                                                                                                                                                                                        | Yes      |
| `targetToken`         | Secret  | Access token for the target repository.                                                                                                                                                                                                     | Yes      |
| `targetURL`           | String  | The HTTPS-format clone URL of the target repository.                                                                                                                                                                                        | Yes      |
| `reference`           | String  | The full reference path to sync from source to target, such as `refs/heads/main` for branches or `refs/tags/v1.2.3` for tags.                                                                                                               | Yes      |
| `referenceShaOld`     | String  | The previous value of the reference on the source repo. Used during updates or deletions to check if the target repo's reference matches the old value before applying changes or deletions. Optional but important for safe forced updates. | No       |
| `syncDelete`          | String  | Indicates if branch or tag deletions on the source repository should be synced to the target repository. Set to `true` to allow deletion syncing, `false` to prevent it. Default is `false`.                                                 | No       |


### Exit Codes
`0`: Sync completed successfully.
`1`: Failure in checking the reference existence.
`2`: Sync failed due to non-fast-forward changes that cannot be forced.
`3`: Sync failed after attempting force push due to source and target being out of sync.
