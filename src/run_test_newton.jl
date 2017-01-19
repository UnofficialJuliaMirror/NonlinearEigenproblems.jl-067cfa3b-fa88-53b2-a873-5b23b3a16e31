#  This is the first code in NEP-pack
workspace()
push!(LOAD_PATH, pwd())	# looks for modules in the current directory
using NEPSolver
using NEPCore
using Gallery


println("Running Newton on random dep")
nep=nep_gallery("dep0")

λ=NaN;
x=NaN
try
    λ,x =newton(nep,displaylevel=1);
catch e
    # Only catch NoConvergence 
    isa(e, NoConvergenceException) || rethrow(e)  
    println("No convergence because:"*e.msg)
    # still access the approximations
    λ=e.λ
    x=e.v
end
println("Resnorm:",compute_resnorm(nep,λ,x))


println("Running Newton on dep with double eigenvalue")
nep=nep_gallery("dep_double")
λ,x =newton(nep,displaylevel=1, λ=8im);
println(λ)
println(compute_resnorm(nep,λ,x))





