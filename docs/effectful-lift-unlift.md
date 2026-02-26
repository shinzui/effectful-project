# Lifting and Unlifting in Effectful

The Effectful library provides various mechanisms for working with effects across different contexts, particularly useful when dealing with higher-order effects, concurrent code, or integrating with external libraries. This document explains the lifting and unlifting mechanisms in the `Effectful.Dispatch.Dynamic` module.

## Core Concepts

### What are Lift and Unlift operations?

- **Lifting**: Converting a computation from one environment to another. In Effectful, lifting generally means taking an effectful computation from a simpler context and running it in a more complex context.

- **Unlifting**: The reverse process - taking a computation from a more complex context and running it in a simpler one. This is particularly important for higher-order effects.

- **Bidirectional Lifting**: Having both lifting and unlifting capabilities simultaneously, which is useful for complex scenarios that require both directions of conversion.

## Unlifting Functions

Unlifting functions are essential for handling higher-order effects, where effect operations take effectful computations as arguments.

### Basic Unlifting Functions

#### `localSeqUnlift`

```haskell
localSeqUnlift
  :: (HasCallStack, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> ((forall r. Eff localEs r -> Eff es r) -> Eff es a)
  -> Eff es a
```

Creates a local unlifting function with the sequential strategy, which is the simplest and most efficient. This allows running a computation from the local effect environment in the handler's effect environment.

Example:

```haskell
runProfiling :: IOE :> es => Eff (Profiling : es) a -> Eff es a
runProfiling = interpret $ \env -> \case
  Profile label action -> localSeqUnlift env $ \unlift -> do
    -- 'action' has type 'Eff localEs a', but we're in 'Eff es'
    -- 'unlift' lets us execute 'action' in our current context
    r <- unlift action
    pure r
```

#### `localSeqUnliftIO`

```haskell
localSeqUnliftIO
  :: (HasCallStack, SharedSuffix es handlerEs, IOE :> es)
  => LocalEnv localEs handlerEs
  -> ((forall r. Eff localEs r -> IO r) -> IO a)
  -> Eff es a
```

Similar to `localSeqUnlift`, but creates an unlifting function that converts from `Eff localEs` directly to `IO`.

Example:

```haskell
runProfiling :: IOE :> es => Eff (Profiling : es) a -> Eff es a
runProfiling = interpret $ \env -> \case
  Profile label action -> localSeqUnliftIO env $ \unlift -> do
    t1 <- getMonotonicTime
    r <- unlift action
    t2 <- getMonotonicTime
    putStrLn $ "Action '" ++ label ++ "' took " ++ show (t2 - t1) ++ " seconds."
    pure r
```

Another example with timeout:

```haskell
data Timeout :: Effect where
  WithTimeout :: Int -> m a -> Timeout m (Maybe a)
  type instance DispatchOf Timeout = Dynamic

runTimeout :: IOE :> es => Eff (Timeout : es) a -> Eff es a
runTimeout = interpret $ \env -> \case
  WithTimeout microseconds action -> localSeqUnliftIO env $ \unlift -> do
    -- Use GHC's timeout function which works in microseconds
    result <- System.Timeout.timeout microseconds (unlift action)
    pure result
```

#### `localUnlift` and `localUnliftIO`

```haskell
localUnlift
  :: (HasCallStack, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> UnliftStrategy
  -> ((forall r. Eff localEs r -> Eff es r) -> Eff es a)
  -> Eff es a

localUnliftIO
  :: (HasCallStack, SharedSuffix es handlerEs, IOE :> es)
  => LocalEnv localEs handlerEs
  -> UnliftStrategy
  -> ((forall r. Eff localEs r -> IO r) -> IO a)
  -> Eff es a
```

These are more general versions that accept an `UnliftStrategy`, allowing for different behaviors depending on the requirements. The strategies are:

- `SeqUnlift`: Sequential unlifting (fastest, but cannot be used across threads)
- `SeqForkUnlift`: Like `SeqUnlift`, but uses a cloned environment
- `ConcUnlift`: Concurrent unlifting that can be used across threads

Example with concurrency:

```haskell
runForkEffect :: IOE :> es => Eff (Fork : es) a -> Eff es a
runForkEffect = interpret $ \env -> \case
  ForkWithUnmask m -> 
    localUnliftIO env (ConcUnlift Persistent Unlimited) $ \unlift -> do
      forkIOWithUnmask $ \unmask -> 
        unlift $ m (\action -> action)
```

## Lifting Functions

Lifting functions allow you to run a computation from a handler's effect environment in the local effect environment.

#### `localSeqLift`

```haskell
localSeqLift
  :: (HasCallStack, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> ((forall r. Eff es r -> Eff localEs r) -> Eff es a)
  -> Eff es a
```

Creates a local lifting function with the sequential strategy, allowing you to run a computation from the current environment in the local environment.

#### `localLift`

```haskell
localLift
  :: (HasCallStack, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> UnliftStrategy
  -> ((forall r. Eff es r -> Eff localEs r) -> Eff es a)
  -> Eff es a
```

General version that accepts an `UnliftStrategy`.

#### `withLiftMap` and `withLiftMapIO`

```haskell
withLiftMap
  :: (HasCallStack, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> ((forall a b. (Eff es a -> Eff es b) -> Eff localEs a -> Eff localEs b) -> Eff es r)
  -> Eff es r

withLiftMapIO
  :: (HasCallStack, SharedSuffix es handlerEs, IOE :> es)
  => LocalEnv localEs handlerEs
  -> ((forall a b. (IO a -> IO b) -> Eff localEs a -> Eff localEs b) -> Eff es r)
  -> Eff es r
```

These utilities help lift mapping functions, useful for transforming effectful computations.

## Bidirectional Lifting Functions

These functions provide both lifting and unlifting capabilities simultaneously.

#### `localLiftUnlift`

```haskell
localLiftUnlift
  :: (HasCallStack, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> UnliftStrategy
  -> ((forall r. Eff es r -> Eff localEs r) -> (forall r. Eff localEs r -> Eff es r) -> Eff es a)
  -> Eff es a
```

Creates both a lifting and an unlifting function, useful for complex scenarios where you need to go both ways.

Example with a resource management system:

```haskell
-- A resource manager effect that needs to communicate both ways
data ResourceManager :: Effect where
  -- This operation needs to move operations both ways between contexts
  WithManagedResource :: (r -> m a) -> (forall x. m x -> m' x) -> (forall y. m' y -> m y) -> ResourceManager m' (m a)
  type instance DispatchOf ResourceManager = Dynamic

-- Implementation for the resource manager
runResourceManager :: IOE :> es => Eff (ResourceManager : es) a -> Eff es a
runResourceManager = interpret $ \env -> \case
  WithManagedResource useResource liftCallback unliftCallback -> 
    -- We need bidirectional communication between effect contexts
    localLiftUnlift env SeqUnlift $ \lift unlift -> do
      -- 1. Create a managed resource
      resource <- createResource
      
      -- 2. Set up callbacks using lift/unlift
      let liftedCallback = \x -> lift (liftCallback (unlift x))
      let unliftedCallback = \y -> unlift (unliftCallback (lift y))
      
      -- 3. Run the resource usage function with the resource
      result <- unlift (useResource resource)
      
      -- 4. Clean up the resource
      cleanupResource resource
      
      pure result

-- Example usage
runApplication :: Eff '[ResourceManager, IOE] ()
runApplication = do
  result <- send $ WithManagedResource 
    (\resource -> pure $ "Using " ++ resource) 
    id  -- lift is identity in this simple example
    id  -- unlift is identity in this simple example
  liftIO $ putStrLn result
```

#### `localLiftUnliftIO`

```haskell
localLiftUnliftIO
  :: (HasCallStack, SharedSuffix es handlerEs, IOE :> es)
  => LocalEnv localEs handlerEs
  -> UnliftStrategy
  -> ((forall r. IO r -> Eff localEs r) -> (forall r. Eff localEs r -> IO r) -> IO a)
  -> Eff es a
```

Similar to `localLiftUnlift` but for lifting from `IO` directly.

Example integrating with a callback-based C library:

```haskell
-- An effect for working with a callback-based C library (e.g., libev)
data EventLoop :: Effect where
  -- Register a callback and receive events from the event loop
  RegisterCallback :: String -> (Event -> m ()) -> m Event -> EventLoop m ()
  type instance DispatchOf EventLoop = Dynamic

-- Implementation that requires bidirectional communication with IO
runEventLoop :: IOE :> es => Eff (EventLoop : es) a -> Eff es a
runEventLoop = interpret $ \env -> \case
  RegisterCallback name callback trigger -> 
    -- We need to both:
    -- 1. Convert IO actions to Eff actions (for receiving events)
    -- 2. Convert Eff actions to IO actions (for callbacks)
    localLiftUnliftIO env SeqUnlift $ \liftIO unliftIO -> do
      -- Create a pointer to a C callback function
      cCallback <- mkCallback $ \rawEvent -> do
        -- Convert the raw event to our Event type
        let event = convertRawEvent rawEvent
        -- Run the callback in the effectful world
        unliftIO (callback event)
      
      -- Register the callback with the C library
      foreignRegisterCallback name cCallback
      
      -- Set up a way to trigger events for testing
      foreignSetTrigger $ \() -> do
        -- When triggered, run the trigger action from our effect world
        event <- unliftIO trigger
        -- Convert and process through the C interface
        processEvent event
```

## Other Related Functions

### `localLend` and `localBorrow`

These functions allow for "lending" effects to or "borrowing" effects from a local environment:

```haskell
localLend
  :: forall lentEs es handlerEs localEs a
   . (HasCallStack, KnownSubset lentEs es, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> UnliftStrategy
  -> ((forall r. Eff (lentEs ++ localEs) r -> Eff localEs r) -> Eff es a)
  -> Eff es a

localBorrow
  :: forall borrowedEs es handlerEs localEs a
   . (HasCallStack, KnownSubset borrowedEs localEs, SharedSuffix es handlerEs)
  => LocalEnv localEs handlerEs
  -> UnliftStrategy
  -> ((forall r. Eff (borrowedEs ++ es) r -> Eff es r) -> Eff es a)
  -> Eff es a
```

Useful for sharing effects between different environments.

Example of `localLend`:

```haskell
-- Let's imagine we have an effect that requires both Logger and Reader Config
data ComplexEffect :: Effect where
  DoSomethingComplex :: ComplexEffect m Int
  type instance DispatchOf ComplexEffect = Dynamic

-- Handler for ComplexEffect requires both Logger and Reader Config
runComplexAction :: (Logger :> es, Reader Config :> es) => Eff es Int

-- Now we want to use this in a handler for another effect that only has Logger
data SimpleEffect :: Effect where
  DoSimpleThing :: SimpleEffect m Int
  type instance DispatchOf SimpleEffect = Dynamic

runSimpleEffect :: (Logger :> es) => Eff (SimpleEffect : es) a -> Eff es a
runSimpleEffect = interpret $ \env -> \case
  DoSimpleThing -> do
    -- We need Reader Config but don't have it in our context
    -- Let's provide it from a local definition
    config <- mkDefaultConfig
    -- Lend the Reader Config effect to the local environment
    localSeqLend @'[Reader Config] env $ \useConfig -> do
      -- Now we can run the complex action with both Logger and Reader Config
      useConfig $ runReader config $ runComplexAction
```

Example of `localBorrow`:

```haskell
-- Effect that needs to use a State effect from the outer context
data BorrowingEffect :: Effect where
  BorrowState :: BorrowingEffect m Int
  type instance DispatchOf BorrowingEffect = Dynamic

-- The handler
runBorrowingEffect :: (State Counter :> es) => Eff (BorrowingEffect : es) a -> Eff es a
runBorrowingEffect = interpret $ \env -> \case
  BorrowState -> 
    -- Borrow the State effect from the local environment to our handler environment
    localSeqBorrow @'[State Counter] env $ \useState -> do
      -- Now we can use the State Counter effect from outer context
      useState $ do
        modify @Counter (+1)
        get @Counter
```

## Common Use Cases

### 1. Higher-Order Effects

The most common use case is implementing handlers for higher-order effects, where operations take effectful computations as arguments.

```haskell
data Bracket :: Effect where
  Bracket :: String -> m a -> (a -> m b) -> m c -> Bracket m c

runBracket :: IOE :> es => Eff (Bracket : es) a -> Eff es a
runBracket = interpret $ \env -> \case
  Bracket label acquire release use -> localSeqUnliftIO env $ \unlift -> 
    bracket 
      (unlift acquire)
      (\a -> unlift (release a))
      (\a -> unlift (use a))
```

### 2. Integrating with External Libraries

When you need to use a library that expects a different monad context:

```haskell
-- Using hedis (Redis) library
data Redis :: Effect where
  RedisCommand :: m a -> Redis.Redis (m a) -> Redis m a
  type instance DispatchOf Redis = Dynamic

runRedis :: IOE :> es => Eff (Redis : es) a -> Eff es a
runRedis = interpret $ \env -> \case
  RedisCommand cleanup cmd -> localSeqUnliftIO env $ \unlift -> do
    conn <- connect defaultConnectInfo
    -- Use the unlift function to run the cleanup action from the local environment
    result <- Redis.runRedis conn cmd
    unlift cleanup  -- Run cleanup action with unlift
    pure result
```

### 3. Concurrent Programming

When working with concurrency, especially when spawning threads:

```haskell
data Async :: Effect where
  Async :: m a -> Async m (Async a)
  Wait :: Async a -> Async m a

runAsync :: IOE :> es => Eff (Async : es) a -> Eff es a
runAsync = interpret $ \env -> \case
  Async action -> localUnliftIO env (ConcUnlift Ephemeral Unlimited) $ \unlift -> do
    async $ unlift action
  Wait asyncA -> liftIO $ wait asyncA
```

## Best Practices

1. **Choose the Right Strategy**: Use `SeqUnlift` by default for efficiency, and only use more complex strategies when needed.

2. **Be Careful with Thread Safety**: When working with concurrency, ensure you use the appropriate unlifting strategy.

3. **Consider Performance**: The more complex strategies (`ConcUnlift`) have higher overhead.

4. **Maintain Effect Compatibility**: Ensure that the environments you're lifting between have compatible effect stacks.

5. **Use `SharedSuffix`**: This constraint ensures that the environments are compatible in a way that makes lifting/unlifting safe.

## Conclusion

The lifting and unlifting functions in Effectful provide powerful tools for working with effectful computations across different contexts. They're particularly important for building higher-order effects, working with concurrency, and integrating with external libraries.

These functions help maintain the separation between the specification of effects and their implementation, which is one of the core principles of Effectful.