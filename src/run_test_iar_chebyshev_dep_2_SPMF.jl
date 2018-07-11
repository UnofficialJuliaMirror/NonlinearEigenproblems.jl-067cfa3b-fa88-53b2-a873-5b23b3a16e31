#workspace(); push!(LOAD_PATH, pwd()); using NEPCore; using NEPTypes; using LinSolvers; using NEPSolver
import NEPSolver.iar_chebyshev; include("../src/method_iar_chebyshev.jl");

n=100; A0=rand(n,n); A1=rand(n,n);

mm=80;  # number of iterations

A1=zeros(A1);
nep=SPMF_NEP([eye(n), A0, A1],[λ->-λ^2,λ->eye(λ),λ->expm(-λ)])

errormeasure=default_errmeasure(nep);   # TODO: understand why one needs to do this

λ,Q,err,V, H = iar_chebyshev(nep,maxit=mm,Neig=20,σ=0.0,γ=1,displaylevel=1,check_error_every=1,errmeasure=errormeasure);
for i=1:length(λ)
    println("Eigenvalue=",λ[i]," residual = ",errormeasure(λ[i],Q[:,i]))
end