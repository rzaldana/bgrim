# Bgrim
An open-source standard library for bash

# Supported Bash versions
4.4.23+

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
Library can be sourced with simple source command:
```bash
# Assuming library is in same directory as sourcing script
source ./bgrim bash 

# Use library functions
bg.log.fatal "exiting script $0"
```

It can also simply be pasted at the beginning of your script. In fact,
this is the recommended approach to avoid having to handle separate
file dependencies and keep your scripts as portable single files

