# Particle: variant R2 (fully rational case; leja + repeated nodes + freeze)

# Intended to be run from nep-pack/ directory or nep-pack/test directory
if !isdefined(:global_modules_loaded)
    workspace()

    push!(LOAD_PATH, string(@__DIR__, "/../../src"))
    push!(LOAD_PATH, string(@__DIR__, "/../../src/nleigs"))

    using NEPCore
    using NEPTypes
    using NleigsTypes
    using Gallery
    using IterativeSolvers
    using Base.Test
end

include("nleigs_test_utils.jl")
include("particle_test_utils.jl")
include("../../src/nleigs/method_nleigs.jl")

verbose = 1

nep, Sigma, Xi, v, nodes, xmin, xmax = particle_init(2)

# solve nlep
@time X, lambda, res, solution_info = nleigs(nep, Sigma, Xi=Xi, displaylevel=verbose > 0 ? 1 : 0, maxdgr=50, minit=30, maxit=100, v=v, nodes=nodes, return_details=verbose > 1)

@testset "NLEIGS: Particle variant R2" begin
    nleigs_verify_lambdas(2, nep, X, lambda)
end

if verbose > 1
    include("nleigs_residual_plot.jl")
    approxSigma = [xmin-im*1e-10, xmin+im*1e-10, xmax+im*1e-10, xmax-im*1e-10]
    nleigs_residual_plot("Particle: variant R2", solution_info, approxSigma)
end
