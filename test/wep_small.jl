# Run tests for the waveguide eigenvalue problem

# Intended to be run from nep-pack/ directory or nep-pack/test directory
push!(LOAD_PATH, string(@__DIR__, "/../src"))
push!(LOAD_PATH, string(@__DIR__, "/../src/gallery_extra"))

using NEPCore
using NEPTypes
using LinSolvers
using NEPSolver
using Gallery
using GalleryWaveguide
using LinearAlgebra
using Random
using Test

import GalleryWaveguide.SchurMatVec

@testset "WEP" begin

nx = 11
nz = 7
nep_spmf=nep_gallery(WEP, nx = nx, nz = nz, benchmark_problem = "TAUSCH", discretization = "FD", neptype = "SPMF")
nep=nep_gallery(WEP, nx = nx, nz = nz, benchmark_problem = "TAUSCH", discretization = "FD", neptype = "WEP")
γ = -1.3-0.31im
v1 = compute_Mlincomb(nep_spmf, γ, ones(size(nep_spmf,1)))
v2 = compute_Mlincomb(nep     , γ, ones(size(nep     ,1)))
@test norm(v1-v2)/norm(v1) < 1e-14

precond = wep_generate_preconditioner(nep, nz, γ)
b1 = rand(ComplexF64, nx*nz)
Schur_fun = SchurMatVec(nep, γ)
b2 = A_ldiv_B!(precond, (Schur_fun*b1))
@test norm(b1-b2)/norm(b1) < 1e-14





nep=nep_gallery(WEP, nx = 3*5*7, nz = 3*5*7, benchmark_problem = "JARLEBRING", discretization = "FD", neptype = "WEP")

λstar=-2.690050173308845 - 3.1436003386330347im  # An exact eigenvalue
n=size(nep,1);

    λ0=-3-3.5im
    v0=ones(n); v0=v0/norm(v0);

    myerrmeasure=(λ,v) -> abs(λ-λstar) # Use eigenvalue error as errmeasure

   λ,v=@time resinv(ComplexF64,nep,displaylevel=1,λ=λ0,v=v0,
              errmeasure=myerrmeasure,tol=1e-12)

    @test  norm(compute_Mlincomb(nep,λ,v))/norm(v)  < 1e-10

    λ,v=@time resinv(ComplexF64,nep,displaylevel=1,λ=λ0,v=v0,
               errmeasure=myerrmeasure,tol=1e-12,linsolvercreator=backslash_linsolvercreator)

    @test  norm(compute_Mlincomb(nep,λ,v))/norm(v)  < 1e-10

    λ,v=@time quasinewton(ComplexF64,nep,displaylevel=1,λ=λ0,v=v0,
                    errmeasure=myerrmeasure,tol=1e-12)

    @test  norm(compute_Mlincomb(nep,λ,v))/norm(v)  < 1e-10


    nev=3
    λ,v=@time iar(ComplexF64,nep,σ=λ0, displaylevel=1,Neig=nev,maxit=100,v=v0,
                  tol=1e-8);

    @test minimum(abs.(λstar-λ))<1e-10

    #λ,v=@time tiar(nep,σ=λ0, displaylevel=1,Neig=nev,maxit=100,v=v0,
    #               tol=1e-8);

end
