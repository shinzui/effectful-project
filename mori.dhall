let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/8415b4b8a746a84eecf982f0f1d7194368bf7b54/package.dhall
        sha256:d19ae156d6c357d982a1aea0f1b6ba1f01d76d2d848545b150db75ed4c39a8a9

in  { project =
      { name = "effectful"
      , namespace = "effectful"
      , type = Schema.PackageType.Library
      , description = Some
          "An easy to use, fast extensible effects library with seamless integration with the existing Haskell ecosystem"
      , language = Schema.Language.Haskell
      , lifecycle = Schema.Lifecycle.Active
      , domains = [ "Effects", "IO" ]
      , owners = [] : List Text
      , origin = Schema.Origin.ThirdParty
      }
    , repos =
      [ { name = "effectful"
        , github = Some "haskell-effectful/effectful"
        , gitlab = None Text
        , git = None Text
        , localPath = Some "effectful"
        }
      , { name = "effectful-extras"
        , github = Some "deepflowinc-oss/effectful-extras"
        , gitlab = None Text
        , git = None Text
        , localPath = Some "effectful-extras"
        }
      ]
    , packages =
      [ { name = "effectful-core"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful-core"
        , description = Some
            "Core effect system primitives without IO integration"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      , { name = "effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful"
        , description = Some
            "Full effect system with IO integration and batteries included"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      , { name = "effectful-plugin"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful-plugin"
        , description = Some "GHC plugin for disambiguating effect operations"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      , { name = "effectful-th"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful-th"
        , description = Some "Template Haskell utilities for effectful"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      , { name = "s3-effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/s3-effectful"
        , description = Some "S3 operations as effectful effects"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      , { name = "time-effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/time-effectful"
        , description = Some "Time operations as effectful effects"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      , { name = "effectful-lens"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/effectful-lens"
        , description = Some "Lens integration for effectful"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      , { name = "typed-process-effectful-extra"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/typed-process-effectful-extra"
        , description = Some "Extra utilities for typed-process-effectful"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      , { name = "random-effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/random-effectful"
        , description = Some "Random number generation as effectful effects"
        , lifecycle = None Schema.Lifecycle
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , runtimeEnvironment = None Schema.RuntimeEnvironment
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        , apiSource = None Schema.ApiSource
        }
      ]
    , bundles =
      [ { name = "effectful"
        , description = Some "Core effectful with TH and plugin support"
        , packages = [ "effectful-core", "effectful", "effectful-th" ]
        , primary = "effectful"
        }
      ]
    , dependencies = [] : List Text
    , apis = [] : List Schema.Api
    , agents = [] : List Schema.AgentHint
    , skills = [] : List Schema.Skill
    , subagents = [] : List Schema.Subagent
    , standards = [] : List Text
    , docs =
      [ { key = "error-guide"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.User
        , description = Some
            "Guide to error handling patterns with effectful"
        , location =
            Schema.DocLocation.LocalFile "docs/effectful-error-guide.md"
        }
      , { key = "lift-unlift"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.User
        , description = Some
            "Guide to lifting and unlifting IO operations in effectful"
        , location =
            Schema.DocLocation.LocalFile "docs/effectful-lift-unlift.md"
        }
      ]
    }
