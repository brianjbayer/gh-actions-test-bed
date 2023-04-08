# gh-actions-test-bed

This is a simple test bed for testing the
[brianjbayer/actions-image-cicd](https://github.com/brianjbayer/actions-image-cicd)
Reusable GitHub Actions CI/CD project.

## How To Use This Test Bed
Generally this test bed is use to test a Pull Request (PR) in
[brianjbayer/actions-image-cicd](https://github.com/brianjbayer/actions-image-cicd)
especially the workflows associated with merging which can only be
properly tested with a merge.

### Make the Changes Under Test
The usual flow is to create the branch and corresponding PR in
`actions-image-cicd`, make the desired changes, and push those
changes to GitHub (origin).

### Make Changes Here to Test
Once the changes are made and pushed for the workflows under test,
create a branch and corresponding PR in this repository and change
the usage of the workflows under test to *reference* the corresponding
branch in `actions-image-cicd` as described in the GitHub Actions
Reusable Workflows documentation
[Calling a reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows#calling-a-reusable-workflow).

This change to reference the branch under test should be enough to
trigger running any PR-related workflows in this repository.  However,
to test any merge-specific workflows under test, the PR in this
repository will need to be merged.  Testing merge-specific workflows
may require several PRs in this repository.

### When Done Testing
If you had to make changes to the
`.github/workflows/on_push_to_main_promote_to_prod.yml` workflow
to test merge-related workflows, you will need to create another
PR in this repository to restore the references for those workflows
under test back to the `main` branch version both as a final test
as well as to prepare this test bed for its next use.

## Running The Project Containers
Although this project is meant as a test bed for the
container-based CI/CD workflows, you may need to run
the project containers for project maintenance or
debugging.

The easiest way to run the containers are with the
included docker compose framework using the
`dockercomposerun` script.

### Deployment Container
To run the default deployment container, run the following command...
```
./script/dockercomposerun
```

This will pull the deployment container from the repository and run the
tests by default.

#### To Build and Run Your Own Deployment Image
If you need to build and run your own deployment image...
1. Run the following command to build a local copy of the deployment
   image...
   ```
   docker build --no-cache -t app .
   ```

2. Run the following command to run your deployment image specifying
   your image with the `APP_IMAGE` environment variable and using
   the CI environment (`-c`) of the docker compose framework...
   ```
   APP_IMAGE=app ./script/dockercomposerun -c
   ```


### Development Environment Container
To run the development environment container, run the following command
to use the Development Environment (`-d` ) of the docker compose
framework...
```
./script/dockercomposerun -d
```

This will pull the development environment container from the repository
and run the interactive Alpine `ash` shell by default.

#### To Build and Run Your Own Development Environment Image
You can also build and run your own development environment image.

1. Run the following command to build a local copy of the development
   environment image...
   ```
   docker build --no-cache --target devenv -t app-dev .
   ```

2. Run the following command to run your development environment
   specifying your image with the `APP_IMAGE` environment variable
   and using the Development Environment (`-d`) of the docker compose
   framework...
   ```
   APP_IMAGE=app-dev ./script/dockercomposerun -d
   ```
