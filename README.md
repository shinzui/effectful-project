# effectful-project

A **Mori corpus project** that tracks the upstream
[`effectful`](https://github.com/haskell-effectful/effectful) ecosystem.

This repository holds no original library code. It is a local mirror plus
curated documentation, registered with Mori as
`mori://effectful/effectful` so that agents and tooling can find
`effectful` source, packages, and guides on disk instead of guessing at APIs
from memory.

## What's here

| Path                | Contents                                                                                |
| ------------------- | --------------------------------------------------------------------------------------- |
| `effectful/`        | `git subtree` of [haskell-effectful/effectful](https://github.com/haskell-effectful/effectful) |
| `effectful-extras/` | `git subtree` of [deepflowinc-oss/effectful-extras](https://github.com/deepflowinc-oss/effectful-extras) |
| `docs/`             | Curated guides written for this corpus, registered as Mori `DocRef`s                     |
| `mori.dhall`        | Mori project manifest: identity, repos, packages, bundles, docs                           |
| `Justfile`          | Recipes for pulling the subtrees from upstream                                            |

### Registered packages

From `effectful/`: `effectful-core`, `effectful`, `effectful-plugin`,
`effectful-th`.

From `effectful-extras/`: `s3-effectful`, `time-effectful`, `effectful-lens`,
`typed-process-effectful-extra`, `random-effectful`.

The `effectful` bundle groups `effectful-core`, `effectful`, and
`effectful-th`, with `effectful` as the primary package.

### Curated docs

| Key                  | Guide                                                                            |
| -------------------- | -------------------------------------------------------------------------------- |
| `error-guide`        | [Error handling patterns](docs/effectful-error-guide.md)                          |
| `lift-unlift`        | [Lifting and unlifting IO operations](docs/effectful-lift-unlift.md)              |
| `upgrade-2.6-to-2.7` | [Migrating from effectful 2.6 to 2.7](docs/effectful-2.6-to-2.7-upgrade.md)       |

## Using it with Mori

```sh
mori registry show effectful --full     # source paths, packages, metadata
mori registry docs effectful            # the curated guides above
mori registry search effectful-core     # locate a package
mori registry dependents effectful      # who depends on effectful
```

## Keeping the mirror current

The vendored trees are `git subtree`s, so updates are ordinary merges:

```sh
just update-effectful          # pull haskell-effectful/effectful master
just update-effectful-extras   # pull deepflowinc-oss/effectful-extras main
just update-all                # both
just log-effectful             # upstream commit log without merging
```

Because the subtrees track upstream `master`/`main` rather than release tags,
the checked-out sources can sit ahead of the newest published Hackage release.
Verify the current released version against Hackage before choosing dependency
bounds or pins.
