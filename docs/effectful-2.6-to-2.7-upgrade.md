# Upgrading from effectful 2.6 to 2.7

This guide covers what changed between `effectful` / `effectful-core` 2.6.1.0
and the 2.7.x series (2.7.0.0 through 2.7.1.3), and how to migrate. It is
derived from the package changelogs and a source diff against the 2.6.1.0
snapshot.

Related packages released alongside:

- `effectful-th` 1.0.0.4 — bug fixes only.
- `effectful-plugin` 2.2.0.0 — improved candidate resolution (see below).

## TL;DR — How hard is it?

| You are...                                                  | Effort                                         |
| ----------------------------------------------------------- | ---------------------------------------------- |
| Using effects and running handlers only                     | Trivial: rename strict `'` functions, fix warnings |
| Writing dynamic handlers (`interpret`, `localSeqUnlift`...) | Mechanical: drop a `LocalEnv` type argument     |
| Using `ProviderList`, `KnownEffects`, `Effectful.Internal.*` | Small, targeted changes                        |
| Relying on `stateM` / `runStateMVar` / `withLiftMap`        | Real refactor, but only deprecated (not removed) |

Recommended lower bounds:

```cabal
build-depends:
    effectful-core >= 2.7.1.1
  , effectful      >= 2.7.1.0
```

Avoid `effectful-core` 2.7.0.0: it has a per-operation performance regression
for dynamically dispatched effects, fixed in 2.7.1.1.

## Breaking changes

### 1. GHC < 9.6 is no longer supported

Applies to `effectful-core`, `effectful`, `effectful-th` and `effectful-plugin`.

### 2. `LocalEnv` lost its `handlerEs` type parameter

The parameter only existed to support `SharedSuffix` constraints, which were
removed (the class is deprecated; runtime sanity checks replace it).

```haskell
-- 2.6
localSeqUnlift
  :: (HasCallStack, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> ((forall r. Eff localEs r -> Eff es r) -> Eff es a)
  -> Eff es a

-- 2.7
localSeqUnlift
  :: HasCallStack
  => LocalEnv localEs
  -> ((forall r. Eff localEs r -> Eff es r) -> Eff es a)
  -> Eff es a
```

**Migration:** anywhere you wrote `LocalEnv localEs handlerEs` in a signature,
write `LocalEnv localEs`, and delete `SharedSuffix` constraints. Handlers whose
types are inferred need no changes.

### 3. `KnownEffects` removed; `ProviderList` uses `KnownSubset`

```haskell
-- 2.7
runProviderList
  :: forall providedEs input f es a
   . (HasCallStack, KnownSubset providedEs (providedEs ++ es))
  => (forall r. HasCallStack => input -> Eff (providedEs ++ es) r -> Eff es (f r))
  -> Eff (ProviderList providedEs input f : es) a
  -> Eff es a
```

**Migration:** replace `KnownEffects providedEs` constraints with
`KnownSubset providedEs (providedEs ++ es)`. For concrete effect lists the
constraint is solved automatically.

### 4. Strict concurrency/mutable modules dropped their ticks (`effectful` only)

To match `strict-mutable-base` 2.0.0.0, `Effectful.Concurrent.MVar.Strict`,
`Effectful.Concurrent.Chan.Strict` and `Effectful.Prim.IORef.Strict` renamed
all exports, including the types:

| Module                              | 2.6                                                                                                                                                                                                                               | 2.7                   |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| `Effectful.Concurrent.MVar.Strict`  | `MVar'`, `newEmptyMVar'`, `newMVar'`, `takeMVar'`, `putMVar'`, `readMVar'`, `swapMVar'`, `tryTakeMVar'`, `tryPutMVar'`, `tryReadMVar'`, `isEmptyMVar'`, `withMVar'`, `withMVar'Masked`, `modifyMVar'`, `modifyMVar'_`, `modifyMVar'Masked`, `modifyMVar'Masked_`, `mkWeakMVar'` | same names, no `'`    |
| `Effectful.Prim.IORef.Strict`       | `IORef'`, `newIORef'`, `readIORef'`, `writeIORef'`, `modifyIORef'`, `atomicModifyIORef'`, `atomicWriteIORef'`, `mkWeakIORef'`                                                                                                     | same names, no `'`    |
| `Effectful.Concurrent.Chan.Strict`  | `Chan'`, `newChan'`, `writeChan'`, `readChan'`, `dupChan'`, `getChan'Contents`, `writeList2Chan'`                                                                                                                                  | same names, no `'`    |

Note that the tick sometimes sat in the middle (`withMVar'Masked` →
`withMVarMasked`, `getChan'Contents` → `getChanContents`).

```haskell
-- 2.6
import Effectful.Concurrent.MVar.Strict (MVar', newMVar', modifyMVar'_)

-- 2.7
import Effectful.Concurrent.MVar.Strict (MVar, newMVar, modifyMVar_)
```

**Watch out for name clashes:** the strict names now coincide with the lazy
ones from `Effectful.Concurrent.MVar`, `Effectful.Prim.IORef`,
`Control.Concurrent.MVar`, `Data.IORef`, etc. Modules that imported both
unqualified will need qualified imports. Also note that `modifyIORef'` in
`Data.IORef` (base) is still a *different* function from the strict module's
new `modifyIORef` — don't blindly search-and-replace across all imports.

### 5. `Effectful.Internal.MTL` renamed

It is now `Effectful.Internal.Effect.Dynamic`. Only relevant if you imported
internals directly.

### 6. Tightened pre-requisites for `unconsEnv` and `unreplaceEnv`

Low-level `Effectful.Internal.Env` functions; only relevant for custom
dispatch machinery.

## Deprecations (warnings, not errors)

| Deprecated                                                                 | Why                                                                                                          | Replacement                                              |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| `stateM`, `modifyM` (all `State` variants) and the dynamic `StateM` operation | Shared: deadlocks if the callback uses the same `State`. Local: silently discards state changes made inside. | Use an explicit `MVar` for atomic effectful updates      |
| `runStateMVar`, `evalStateMVar`, `execStateMVar`                           | Decouples shared `State`'s representation from `MVar`                                                        | Manage an explicit `MVar` yourself                       |
| `withLiftMap`                                                              | Misuse across threads is undefined behavior, undetectable at runtime                                         | `localLiftUnlift` with an appropriate `UnliftStrategy`   |
| `SharedSuffix`                                                             | Replaced by runtime sanity checks                                                                            | Just delete the constraint                               |

Example migration away from `stateM` on shared state:

```haskell
-- 2.6 (deprecated in 2.7; deadlocks if `act` touches the same State)
bump :: (State.State Int :> es, IOE :> es) => Eff es ()
bump = State.stateM $ \n -> do
  n' <- act n
  pure ((), n')

-- 2.7
bump :: (Reader (MVar Int) :> es, Concurrent :> es) => Eff es ()
bump = do
  var <- ask
  modifyMVar_ var act
```

## New features

### New effects (`effectful-core`, re-exported from `effectful`)

- **`Input`** — access to values.
  `Effectful.Input.Static`, `Effectful.Input.Static.Action`,
  `Effectful.Input.Dynamic`, `Effectful.Labeled.Input`.

  ```haskell
  input :: (HasCallStack, Input i :> es) => Eff es i
  ```

- **`Output`** — accumulation of values, with several storage strategies:
  `Effectful.Output.Static.Local.List`, `...Local.Array`,
  `...Shared.List`, `...Shared.Array`, `Effectful.Output.Static.Action`,
  `Effectful.Output.Dynamic`, `Effectful.Labeled.Output`.

  ```haskell
  -- Effectful.Output.Static.Local.List
  output    :: (HasCallStack, Output o :> es) => o -> Eff es ()
  runOutput :: HasCallStack => Eff (Output o : es) a -> Eff es (a, [o])
  ```

- **`ReturnWith`** — early return from a computation.
  `Effectful.ReturnWith.Static`, `Effectful.ReturnWith.Dynamic`,
  `Effectful.Labeled.ReturnWith`.

  ```haskell
  runReturnWith :: HasCallStack => Eff (ReturnWith r : es) r -> Eff es r
  returnWith    :: (HasCallStack, ReturnWith r :> es) => r -> Eff es a
  ```

### Provider changes

- `Provider` and `ProviderList` are now **dynamically dispatched** and their
  operations are exported.
- Labeled variants: `Effectful.Labeled.Provider`,
  `Effectful.Labeled.Provider.List`.
- `Labeled(..)` is re-exported from every `Effectful.Labeled.*` module.

### Error handling

- `rethrowErrorWith`, `rethrowError`, `rethrowError_` (and the dynamic
  `RethrowErrorWith` operation) throw an `Error e` with a *given* `CallStack`,
  useful for re-raising a caught error without losing its origin:

  ```haskell
  rethrowError :: (Error e :> es, Show e) => CallStack -> e -> Eff es a

  foo = action `catchError` \cs e -> do
    logIt e
    rethrowError cs e
  ```

- With `base` >= 4.21, if the cleanup of `bracket`, `bracket_`,
  `bracketOnError`, `finally` or `onException` throws, the original exception
  is kept in a `WhileHandling` annotation instead of being lost.
- `MonadThrow`/`MonadCatch` instances for `Eff` define `rethrowM` and
  `catchNoPropagate` when built with `exceptions` >= 0.10.11.

### Dispatch API

- `localLendBorrow` in `Effectful.Dispatch.Dynamic` — lend and borrow effects
  between the handler and local environments in one step.
- 2.7.1.0: `seqForkUnliftIO` exported and `unsafeSeqForkUnliftIO` added in
  `Effectful.Dispatch.Static`; `type (++)` exported from
  `Effectful.Dispatch.Dynamic`; `handleJust` no longer has a spurious
  `HasCallStack` constraint.

### File system (`effectful`)

- `OsPath` variants: `Effectful.FileSystem.OsPath` (for
  `System.Directory.OsPath`) and `Effectful.FileSystem.File.OsPath` (for
  `System.File.OsPath` from `file-io`).

### Backends

- 2.7.1.2: the library works with GHC's JavaScript backend.

## Behavior changes to watch for

These compile unchanged but may alter runtime behavior:

- **`runInBoundThread` / `runInUnboundThread`** (`Effectful.Concurrent`) no
  longer run the computation in a cloned environment, so modifications to
  thread-local effects (e.g. `State.Static.Local`) made inside are now
  *kept* instead of discarded.
- **`runPureEff`** (2.7.1.2+) runs the computation in a separate thread. This
  fixes values being permanently poisoned by an asynchronous exception
  delivered to a forcing thread
  ([#380](https://github.com/haskell-effectful/effectful/issues/380)). Since
  2.7.1.3 the worker is killed when its result becomes unreachable.
- **Performance:** 2.7.0.0 regressed dynamic dispatch overhead; fixed in
  2.7.1.1.
- **`effectful-plugin` 2.2.0.0** now considers effects from the context as
  candidates even when the effect row is (partially) concrete. Code that the
  plugin previously resolved by silently favouring the row may now be reported
  as genuinely ambiguous — add a type application or annotation.

## Bug fixes (no action required)

- `restoreStorageData` no longer shrinks storage capacity (could cause
  out-of-bounds reads via escaped unlifting functions).
- `localLiftUnlift` with `SeqForkUnlift` or `ConcUnlift Persistent` now shares
  effect storage correctly and applies the thread limit jointly.
- `NonDet`'s `OnEmptyRollback` now rolls back local state of static effects
  stored in mutable variables.
- `ConcUnlift Persistent` thread registration interrupted by an async exception
  no longer leaks a finalizer that corrupts thread-limit accounting.
- Running the setup computation of `reinterpret`/`impose` in a cloned
  environment now fails immediately with an accurate error instead of
  corrupting the call site's environment.
- `effectful-th` 1.0.0.4: correct signatures when a constructor mentions the
  monad variable in its context or in effect type arguments; fixity
  annotations transferred to generated functions; friendly error for
  mis-kinded effect parameters restored.
- `effectful-plugin` 2.2.0.0: no compiler panic on constraints headed by a
  type variable or quantified constraints.

## Migration checklist

1. Ensure GHC >= 9.6.
2. Bump bounds: `effectful-core >= 2.7.1.1`, `effectful >= 2.7.1.0`
   (and `effectful-plugin >= 2.2`, `effectful-th >= 1.0.0.4` if used).
3. Rename ticked identifiers from the `*.Strict` MVar/Chan/IORef modules;
   resolve any resulting import clashes with qualified imports.
4. Remove the second type argument from `LocalEnv` in handler signatures and
   delete `SharedSuffix` constraints.
5. Replace `KnownEffects` with `KnownSubset providedEs (providedEs ++ es)`.
6. Update imports of `Effectful.Internal.MTL` →
   `Effectful.Internal.Effect.Dynamic`.
7. Build with `-Wall`, then address deprecations: `stateM`/`modifyM`,
   `runStateMVar` family, `withLiftMap`.
8. Review uses of `runInBoundThread`/`runInUnboundThread` that relied on local
   state changes being discarded.
9. If using `effectful-plugin`, add annotations where GHC now reports
   ambiguity.

## Sources

- `effectful/effectful-core/CHANGELOG.md`
- `effectful/effectful/CHANGELOG.md`
- `effectful/effectful-th/CHANGELOG.md`
- `effectful/effectful-plugin/CHANGELOG.md`
