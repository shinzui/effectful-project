let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/93104153ecf8817547229a867302a70a25c4b3d8/package.dhall
        sha256:5e00bba267f27069df1d3caadfec2ec6a8c4e797ce652d78c09528f981b71b42

in  Schema.Project::{ project =
      Schema.ProjectIdentity::{ name = "effectful"
      , namespace = "effectful"
      , type = Schema.PackageType.Library
      , description = Some
          "An easy to use, fast extensible effects library with seamless integration with the existing Haskell ecosystem"
      , language = Schema.Language.Haskell
      , lifecycle = Schema.Lifecycle.Active
      , domains = [ "Effects", "IO" ]
      , origin = Schema.Origin.ThirdParty
      }
    , repos =
      [ Schema.Repo::{ name = "effectful"
        , github = Some "haskell-effectful/effectful"
        , localPath = Some "effectful"
        }
      , Schema.Repo::{ name = "effectful-extras"
        , github = Some "deepflowinc-oss/effectful-extras"
        , localPath = Some "effectful-extras"
        }
      ]
    , packages =
      [ Schema.Package::{ name = "effectful-core"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful-core"
        , description = Some
            "Core effect system primitives without IO integration"
        }
      , Schema.Package::{ name = "effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful"
        , description = Some
            "Full effect system with IO integration and batteries included"
        }
      , Schema.Package::{ name = "effectful-plugin"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful-plugin"
        , description = Some "GHC plugin for disambiguating effect operations"
        }
      , Schema.Package::{ name = "effectful-th"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful/effectful-th"
        , description = Some "Template Haskell utilities for effectful"
        }
      , Schema.Package::{ name = "s3-effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/s3-effectful"
        , description = Some "S3 operations as effectful effects"
        }
      , Schema.Package::{ name = "time-effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/time-effectful"
        , description = Some "Time operations as effectful effects"
        }
      , Schema.Package::{ name = "effectful-lens"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/effectful-lens"
        , description = Some "Lens integration for effectful"
        }
      , Schema.Package::{ name = "typed-process-effectful-extra"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/typed-process-effectful-extra"
        , description = Some "Extra utilities for typed-process-effectful"
        }
      , Schema.Package::{ name = "random-effectful"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "effectful-extras/random-effectful"
        , description = Some "Random number generation as effectful effects"
        }
      ]
    , bundles =
      [ Schema.PackageBundle::{ name = "effectful"
        , description = Some "Core effectful with TH and plugin support"
        , packages = [ "effectful-core", "effectful", "effectful-th" ]
        , primary = "effectful"
        }
      ]
    , docs =
      [ Schema.DocRef::{ key = "error-guide"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.User
        , description = Some
            "Guide to error handling patterns with effectful"
        , location =
            Schema.DocLocation.LocalFile "docs/effectful-error-guide.md"
        }
      , Schema.DocRef::{ key = "lift-unlift"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.User
        , description = Some
            "Guide to lifting and unlifting IO operations in effectful"
        , location =
            Schema.DocLocation.LocalFile "docs/effectful-lift-unlift.md"
        }
      ]
    }
