# Run tests on Beyns contour integral method 

# Intended to be run from nep-pack/ directory or nep-pack/test directory
workspace()
push!(LOAD_PATH, pwd()*"/src")	
push!(LOAD_PATH, pwd()*"/src/gallery_extra")
push!(LOAD_PATH, pwd()*"/src/gallery_extra/waveguide")	

using NEPSolver
using NEPCore
using NEPTypes
using Gallery
using LinSolvers

using Base.Test



nep_org=nlevp_gallery_import("gun","../nlevp3/");
nep1=nlevp_make_native(nep_org);

n=size(nep1,1);
tol=1e-11;
λ1,v1=quasinewton(nep1,λ=150^2+1im,v=ones(n),displaylevel=1,tolerance=tol,maxit=500);

v1=v1/norm(v1);

@test norm(compute_Mlincomb(nep1,λ1,v1))<tol*100
@test norm(compute_Mder(nep1,λ1)*v1)<tol*100

@test norm(compute_Mlincomb(nep_org,λ1,v1))<tol*100
@test norm(compute_Mder(nep_org,λ1)*v1)<tol*100


# Check comput_MM is correct (for diagonal matrix)
V=randn(n,3)+randn(n,3);
s=randn(3)+1im*randn(3);
S=diagm(s);
N1=compute_MM(nep1,S,V);
N2=hcat(compute_Mlincomb(nep_org,s[1],V[:,1]),
        compute_Mlincomb(nep_org,s[2],V[:,2]),
        compute_Mlincomb(nep_org,s[3],V[:,3]))
@test norm(N1-N2)<sqrt(eps())


# Check that two steps of quasinewton always gives the same resul
λ_org=0
try
    quasinewton(nep_org,maxit=2,λ=150^2+1im,v=ones(n),displaylevel=1)
catch e
    λ_org=e.λ
end


λ1=0
try
    quasinewton(nep1,maxit=2,λ=150^2+1im,v=ones(n),displaylevel=1)
catch e
    λ1=e.λ
end

@test abs(λ1-λ_org)<sqrt(eps())

    
