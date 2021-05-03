# MemoryExperiments
This is all the code needed to analyse the data from the memory experiments. 

## Requirements
You'll need a new version of Julia installed (see [here](https://julialang.org/downloads/) for instructions on how to install Julia).

## How to use
The easiest way is to start a new Julia REPL (e.g. by double-clicking the Julia icon), and copy-pasting this:
```julia
import LibGit2
mktempdir() do path
  LibGit2.clone("https://github.com/yakir12/MemoryExperiments", path) 
  include(joinpath(path, "main.jl"))
end
```
and all the figures and statistics are saved in a folder called `MemoryExperiments results` at your home directory.

For better control, you can:
1. Download this repository.
2. Start a new Julia REPL inside the downloaded folder. One way to accomplish this is with `cd("<path>")` where `<path>` is the path to the dowloaded MemoryExperiments folder. For instance, if you've downloaded this git-repository to your home directory, then `cd(joinpath(homedir(), "MemoryExperiments"))` should work.
3. Simply run the `main.jl`-file with:
   ```julia
   include("main.jl")
   ```
4. All the figures and statistics have been generated in the `MemoryExperiments results` folder.
