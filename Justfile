# List available recipes
default:
    @just --list

# Update effectful subtree from upstream master
update-effectful:
    git subtree pull --prefix=effectful https://github.com/haskell-effectful/effectful.git master

# Update effectful-extras subtree from upstream main
update-effectful-extras:
    git subtree pull --prefix=effectful-extras https://github.com/deepflowinc-oss/effectful-extras.git main

# Update all subtrees from upstream
update-all: update-effectful update-effectful-extras

# Show commit log from effectful upstream
log-effectful:
    git fetch https://github.com/haskell-effectful/effectful.git master
    git log --oneline FETCH_HEAD
