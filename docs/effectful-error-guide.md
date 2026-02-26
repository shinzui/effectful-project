# Error Effect Guide

The Error effect in Effectful provides a robust mechanism for handling typed errors (checked exceptions) in a functional way. Unlike regular Haskell exceptions, Error effects are tracked in the type system and must be explicitly handled.

## Overview

The Error effect comes in two variants:
- **Static dispatch** (`Effectful.Error.Static`) - recommended for most use cases
- **Dynamic dispatch** (`Effectful.Error.Dynamic`) - for runtime interpretation changes

## Key Concepts

### Error vs Exception

The Error effect is **not** for handling regular Haskell exceptions. It's specifically for checked exceptions that are tracked in the type system:

```haskell
-- This will NOT be caught by Error handlers
boom = error "BOOM!"
runEff . runError @ErrorCall $ boom `catchError` \_ (_::ErrorCall) -> pure "caught"
-- *** Exception: BOOM!

-- Use Effectful.Exception for regular exceptions
runEff $ boom `E.catch` \(_::ErrorCall) -> pure "caught"
-- "caught"
```

### Order Independence

Unlike monad transformers (ExceptT), the order of Error handlers relative to other effects doesn't affect state semantics:

```haskell
-- With transformers - order matters for state handling
(`T.runStateT` "Hi") . T.runExceptT $ action  -- state may be lost
T.runExceptT . (`T.runStateT` "Hi") $ action  -- different behavior

-- With Effectful - order doesn't matter
runEff . runState "Hi" . runError @String $ action  -- consistent
runEff . runError @String . runState "Hi" $ action  -- same behavior
```

## Static Dispatch (Recommended)

### Basic Usage

```haskell
import Effectful
import Effectful.Error.Static

-- Define a custom error type
data MyError = InvalidInput String | NetworkError Int
  deriving (Show, Eq)

-- Computation that might fail
validateInput :: Error MyError :> es => String -> Eff es Int
validateInput input
  | null input = throwError (InvalidInput "empty input")
  | length input > 10 = throwError (InvalidInput "input too long")
  | otherwise = pure (length input)

-- Handler with complete error information
example1 :: IO (Either (CallStack, MyError) Int)
example1 = runEff . runError $ validateInput "hello"

-- Handler without CallStack
example2 :: IO (Either MyError Int)
example2 = runEff . runErrorNoCallStack $ validateInput ""

-- Handler with custom error handling
example3 :: IO String
example3 = runEff . runErrorWith handler $ validateInput ""
  where
    handler _cs (InvalidInput msg) = pure $ "Input error: " ++ msg
    handler _cs (NetworkError code) = pure $ "Network error: " ++ show code
```

### Core Operations

#### Throwing Errors

```haskell
-- Throw with show as display function
throwError :: (HasCallStack, Error e :> es, Show e) => e -> Eff es a

-- Throw with custom display function
throwErrorWith :: (HasCallStack, Error e :> es) => (e -> String) -> e -> Eff es a

-- Throw with opaque display (for sensitive data)
throwError_ :: (HasCallStack, Error e :> es) => e -> Eff es a
```

#### Catching Errors

```haskell
-- Basic error catching
catchError :: (HasCallStack, Error e :> es)
           => Eff es a                    -- computation
           -> (CallStack -> e -> Eff es a) -- handler
           -> Eff es a

-- Flipped version for shorter handlers
handleError :: (HasCallStack, Error e :> es)
            => (CallStack -> e -> Eff es a) -- handler
            -> Eff es a                    -- computation
            -> Eff es a

-- Try-style error handling
tryError :: (HasCallStack, Error e :> es)
         => Eff es a
         -> Eff es (Either (CallStack, e) a)
```

## Dynamic Dispatch

Dynamic dispatch allows changing error interpretation at runtime:

```haskell
import Effectful.Error.Dynamic

-- Same operations as static, but with runtime flexibility
dynamicExample :: IO (Either (CallStack, String) ())
dynamicExample = runEff . runError $ do
  throwError "something went wrong"
  pure ()
```

The dynamic variant reinterprets to the static implementation internally, providing the same semantics with additional runtime flexibility.

## ErrorWrapper Implementation

The `ErrorWrapper` is an internal data type used by the static Error effect to implement typed error handling:

```haskell
data ErrorWrapper = ErrorWrapper !ErrorId CallStack String Any
```

### Components

1. **ErrorId**: A unique identifier (`newtype ErrorId = ErrorId Unique`) that ensures different Error handlers for the same type don't interfere with each other
2. **CallStack**: Captures the call stack at the point where the error was thrown
3. **String**: Display representation of the error (from the display function)
4. **Any**: Type-erased storage of the actual error value

### Purpose

The ErrorWrapper serves several critical functions:

1. **Type Safety**: Allows storing errors of any type while maintaining type safety through the ErrorId
2. **Isolation**: Different Error handlers (even for the same error type) have unique ErrorIds, preventing cross-contamination
3. **Exception Integration**: Implements the Exception typeclass to integrate with Haskell's exception system
4. **Stack Traces**: Preserves CallStack information for debugging

### Exception Behavior

```haskell
instance Exception ErrorWrapper where
  -- Treated as async exception for proper cleanup semantics
  toException = asyncExceptionToException
  fromException = asyncExceptionFromException
```

This ensures that Error effects work correctly with resource cleanup and can be properly masked/unmasked.

### Matching Mechanism

```haskell
matchError :: ErrorId -> ErrorWrapper -> Maybe (CallStack, e)
matchError eid (ErrorWrapper etag cs _ e)
  | eid == etag = Just (cs, fromAny e)  -- Same handler, extract error
  | otherwise = Nothing                 -- Different handler, ignore
```

Only ErrorWrappers with matching ErrorIds are caught by a specific Error handler, ensuring proper isolation.

## Best Practices

### 1. Use Descriptive Error Types

```haskell
data ValidationError 
  = EmptyField String
  | InvalidFormat String String  -- field, expected format
  | OutOfRange String Int Int    -- field, value, max
  deriving (Show, Eq)
```

### 2. Provide Good Display Functions

```haskell
displayValidationError :: ValidationError -> String
displayValidationError = \case
  EmptyField field -> field ++ " cannot be empty"
  InvalidFormat field fmt -> field ++ " must be in format: " ++ fmt
  OutOfRange field val max -> field ++ " value " ++ show val ++ " exceeds maximum " ++ show max

-- Usage
throwErrorWith displayValidationError (EmptyField "username")
```

### 3. Layer Error Types

```haskell
data DatabaseError = ConnectionFailed | QueryTimeout | InvalidQuery String
data BusinessError = InvalidUser | InsufficientFunds | ValidationError ValidationError

-- Handle at appropriate levels
processUser :: (Error DatabaseError :> es, Error BusinessError :> es) => UserId -> Eff es User
```

### 4. Use Resource-Safe Operations

```haskell
safeOperation :: Error MyError :> es => Eff es Result
safeOperation = bracket
  (liftIO openResource)
  (liftIO . closeResource)
  (\resource -> do
    result <- processWithResource resource
    when (isInvalid result) $ throwError InvalidResult
    pure result)
```

## Advanced Patterns

### Error Accumulation

```haskell
import Effectful.Writer.Static.Local

validateFields :: (Error ValidationError :> es, Writer [ValidationError] :> es) 
               => Fields -> Eff es ValidatedFields
validateFields fields = do
  name <- validateName (fieldName fields) `catchError` \_ e -> do
    tell [e]
    pure ""
  email <- validateEmail (fieldEmail fields) `catchError` \_ e -> do
    tell [e] 
    pure ""
  -- ... continue with other fields
  pure $ ValidatedFields name email
```

### Retrying with Errors

```haskell
retryOnError :: Error e :> es => Int -> Eff es a -> Eff es a
retryOnError 0 action = action
retryOnError n action = action `catchError` \cs e -> 
  if isRetryable e then retryOnError (n-1) action else throwErrorWith (show e)
```

## Migration from Transformers

When migrating from ExceptT:

```haskell
-- Before (transformers)
type AppM = ExceptT AppError (StateT AppState IO)

runApp :: AppM a -> AppState -> IO (Either AppError (a, AppState))
runApp action = runStateT (runExceptT action)

-- After (effectful)
type AppEffs = '[Error AppError, State AppState, IOE]

runApp :: Eff AppEffs a -> AppState -> IO (Either (CallStack, AppError) (a, AppState))
runApp action state = runEff . runState state . runError $ action
```

The main advantages:
- Order independence
- Better performance
- Cleaner composition
- Integrated stack traces
- Resource safety