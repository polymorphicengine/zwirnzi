# zwirnzi

🧶🧵🧶 The Zwirn Zompiler Interpreter 🧶🧵🧶

# Installation

Pre-built binaries for zwirnzi can be downloaded [here](https://github.com/polymorphicengine/zwirnzi/releases/). Note that the windows and mac builds have not been tested.

## Manual Installation

```git clone https://github.com/polymorphicengine/zwirnzi
cd zwirnzi
cabal build
```

to run:
`cabal run`

## Manual Installation of the dev-branch

You need to make sure that you have the dev versions of both [zwirn](https://github.com/polymorphicengine/zwirn) and [zwirn-core](https://lab.al0.de/martin/zwirn-core).
in the zwirnzi source repository, create a `cabal.project.local` file with the following content:
```
ignore-project: False
source-repository-package
     type: git
     location: path/to/zwirn (source of dev branch)
source-repository-package
     type: git
     location: path/to/zwirn-core (source of dev branch)
```

You can then proceed as in the manual installation of the main branch.
