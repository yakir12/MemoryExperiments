# MemoryExperiments
This is all the code needed to analyse the data from the memory experiments. It produces the figures used in the article as well as a `stats.csv` file with all the data used to produce these figures and more (i.e. `runid`, `beetle ID`, `date`, `feeder to nest`, `holding condition`, `holding time`, `speed μ±σ`, `vector length`, `path length`, `nest corrected vector`, `angular difference`)

## Requirements
You'll need a new version of Julia installed (see [here](https://julialang.org/downloads/) for instructions on how to install Julia).

## How to use
1. Download this repository.
2. Start a new Julia REPL inside the downloaded folder. One way to accomplish this is with `cd("<path>")` where `<path>` is the path to the downloaded MemoryExperiments folder. For instance, if you've downloaded this git-repository to your home directory, then `cd(joinpath(homedir(), "MemoryExperiments"))` should work.
3. Simply run the `main.jl`-file with:
   ```julia
   include("main.jl")
   ```
4. All the figures and statistics have been generated in the `MemoryExperiments results` folder.
If this did not work, try the next section.

## Troubleshooting
Start a new Julia REPL (e.g. by double-clicking the Julia icon), and copy-paste:
```julia
import LibGit2
mktempdir() do path
  LibGit2.clone("https://github.com/yakir12/MemoryExperiments", path) 
  include(joinpath(path, "main.jl"))
end
```
All the figures and statistics are saved in a folder called `MemoryExperiments results` at your home directory.
