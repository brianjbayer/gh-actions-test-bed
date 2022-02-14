# gh-actions-test-bed

This is a hopefully simple test bed for testing CI/CD
with GitHub Actions.

## Running containerized locally
### Deploy
Default...
```
./script/dockercomposerun
```

Interactive...
```
./script/dockercomposerun sh
```

### Dev Environment
  1. Build it...
     ```
     docker build --no-cache --target devenv -t app-dev .
     ```
  2. Run it (interactively)...
     ```
     APP_IMAGE=app-dev ./script/dockercomposerun sh
     ```

