using Distributed
using StatsBase
using MultivariateStats
using Distributions

# number of cores
ncores = length(Sys.cpu_info()) - 1
if nprocs() == 1
    addprocs(ncores)
end

include("CYCLOPS_2a_PreNPostprocessModule.jl")
include("CYCLOPS_2a_AutoEncoderModule.jl")

include("CYCLOPS_2a_MCA.jl")
include("CYCLOPS_2a_MultiCoreModule_Smooth.jl")
include("CYCLOPS_2a_Seed.jl")
include("CYCLOPS_2a_CircularStats_U.jl")

using DataFrames
using CSV
data = CSV.read("/Volumes/Unititled/Jan-Apr-2019/CYCLOPS/RNA_DATA.csv")[1:end, 2:end]
describe(data)
genes = 1:100 # which genes to look at


Frac_Var=0.85 # Set Number of Dimensions of SVD to maintain this fraction of variance
DFrac_Var=0.03 # Set Number of Dimensions of SVD to so that incremetal fraction of variance of var is at least this much
N_best =40 # Number of random initial conditions to try for each optimization

total_background_num=40; # Number of background runs for global background ref
n_cores=5; # Number of machine cores
