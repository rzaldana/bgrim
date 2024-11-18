# <p align="center">📖🧙 bgrim</p>
An open-source standard library for bash

# Dependencies
bgrim is pure bash code so there are no external binary dependencies (not even GNU core utilities). This is by design to make the library compatible with as many platforms as possible (as long as they're running a supported bash version).

# Supported Bash versions
The following Bash versions are tested on Linux Alpine:
- 4.4.23
- 5.2.15

However, given the small differences between minor Bash versions and different platform binaries, the library sshould be broadly compatible with any Bash versions higher than 4.4.23. Bash versions lower than that, are explicitly not supported.

**IMPORTANT NOTE FOR MACOS USERS**: By default, MacOS ships with an ancient version of Bash (3.2.57). This version lacks some important features used by the library, including but not limited to associative arrays and the lastpipe shopt. This library will not run on your system unless you upgrade to a higher version of Bash.

# Modules
- **arr**: functions for array manipulation
- **cli**: command line arguments parser
- **env**: functions for manipulation of execution environment
- **func**: functions for bash function manipulation
- **in**: functions for function input validation 
- **log**: logging functions
- **str**: functions for string manipulation and validation
- **trap**: functions for manipulation of traps
- **tty**: functions for tty-specific output (e.g. colored and bold text)
- **var**: functions for manipulation of bash variables

# Usage
## Source
Library can be sourced with simple source command:
```bash
# Assuming library is in same directory as sourcing script
source ./bgrim bash 

# Use library functions
__BG_LOG_LEVEL=INFO
bg.log.info "exiting script $0"
```

## Just paste
It can also simply be pasted at the beginning of your script. In fact,
this is the recommended approach to avoid having to handle separate
file dependencies and keep your scripts as portable single files. For example,
if you have a script `orinal-script.bash` that looks like this:
```bash
# Use library functions
__BG_LOG_LEVEL=INFO
bg.log.info "exiting script $0"
```

You can simply create a new file with the library code at the top,
followed by your script, as follows:
```bash
cat ./bgrim.bash >> new-script.bash
cat ./original-script.bash >> new-script.bash
```

You can copy the library into your script in any other way but you
need to make sure the library code comes *BEFORE* any code that
depends on it.


# Docs
All functions documented inline. 

# Contributing
## Development Dependencies
- git v2.44.0+
- bash v4.4.23+ installed on your machine (necessary to run build and test scripts)
- docker cli v27.2.0+

## Running tests
To run the library's tests, simply run the following commands from this repository's root:
```bash
make configure
make test
```

The `make configure` fetches all git submodules associated with this repo. Most notably, it fetches the [bash_unit](https://github.com/pgrange/bash_unit) repo, which contains the `bash_unit` script, which is used to run the library's tests.

The `make test` command runs the `scripts/test` script, which runs the unit tests once per each of the supported bash versions. For each bash version, the tests are run in an Alpine Docker container running the specified bash version. These docker containers are modified using the Dockerfile in the 'scripts' directory. To add a new tested version, add the version string to the `SUPPORTED_VERSIONS` array at the top of the `scripts/test` script.

Tests are in the `tests` directory. Each file with a filename that follows the `test_*.bash` naming convention contains test cases to be run. To add a new test, simply add a function with a name that starts with `test_` to one of the test files or to a new test file. The new file will be run with the other tests when you invoke 'make test', as long as it follows hte `test_*.bash` naming convention. 

## Adding new features
Each test file in the `tests/` directory corresponds to a file in the `src/` directory. All tests for functions in that file should be in the corresponding `tests/test_*.bash` test file. To add a new function or make a change to a new function, first edit the test in the corresponding test file or add a new file, then run `make test` and make sure the new test fails. Then edit the function or add a new function in the corresponding file in `/src`. Once all your tests are passing again, run `make build` from the repo's root directory. This will aggregate all files in the `src/` directory into a single file `bgrim.bash` at the root of the repo that is the built library.

