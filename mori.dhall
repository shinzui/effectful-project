let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/28dfc529336f0c92a846f074b5f19c6442394a84/package.dhall
        sha256:dda2cb9c528a0edac9c5ba7aeb14517d153ec612ec70c30115bb6749f15df15b

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
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        }
      , { name = "effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful"
        , description = Some
            "Full effect system with IO integration and batteries included"
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        }
      , { name = "effectful-plugin"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful-plugin"
        , description = Some "GHC plugin for disambiguating effect operations"
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        }
      , { name = "effectful-th"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful-th"
        , description = Some "Template Haskell utilities for effectful"
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
        }
      , { name = "effectful-extras"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras"
        , description = Some "Extra utilities and combinators for effectful"
        , visibility = Schema.Visibility.Public
        , runtime = { deployable = False, exposesApi = False }
        , dependencies = [] : List Schema.Dependency
        , docs = [] : List Schema.DocRef
        , config = [] : List Schema.ConfigItem
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
