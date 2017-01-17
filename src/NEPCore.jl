module NEPCore

    export NEP
    export DEP
    export PEP
    export size
    export NoConvergenceException
    export LinSolver

    # Core interfaces
    export compute_Mder
    export compute_Mlincomb
    export compute_MM

    # NEP-functions
    export compute_resnorm
    export compute_rf


    # Helper functions
    export compute_Mlincomb_from_MM
    export compute_Mlincomb_from_Mder

    export default_errmeasure

    import Base.size  # Overload for nonlinear eigenvalue problems
    #using Combinatorics; 

    """
Determines if a method is defined for the concrete class.
False will be returned if methodname is only defined for the
abstract superclass of s.
"""
    macro method_concretely_defined(methodname,s)
        return :(length(methodswith(typeof($s), $methodname, false))>0)
    end


    abstract NEP;


    ############################################
    # Default NEP functions
    #
    """
    compute_Mder(nep::NEP,λ::Number,i::Integer=0)    
 Computes the ith derivative of NEP evaluated in λ\\
 Usage:\\
   compute_Mder(nep,λ)  # Evaluate NEP in λ
"""
    function compute_Mder(nep::NEP,λ::Number,i::Integer=0)
        error("You need to provide an implementation of Mder for this NEP")
        return 0;
    end

    function compute_Mlincomb(nep::NEP,λ::Number,V;a=ones(size(V,2)))
        # determine a default behavior (may lead to loss of performance) 
        if (@method_concretely_defined(compute_MM,nep))
            return compute_Mlincomb_from_MM(nep,λ,V,a)
        elseif (@method_concretely_defined(compute_Mder,nep))
            return compute_Mlincomb_from_Mder(nep,λ,V,a)
        else
            error("No procedure to compute Mlincomb")
        end
    end

    function compute_MM(nep::NEP,S,V)
        error("No procedure to compute MM")
    end




    ## Helper functions 
    function compute_Mlincomb_from_MM(nep::NEP,λ::Number,V,a)
        #println("Using poor-man's compute_MM -> compute_Mlincomb")
        k=size(V,2)
        S=jordan_matrix(k,λ,T=typeof(V[1])).'
        b=zeros(size(a));
        for i=1:k
            b[i]=a[i]*factorial(i-1)
        end
        W=V*diagm(b)
        z=compute_MM(nep,S,W)*eye(k,1)
        ## activate following for debugging (verify that Mder is equivalent)
        # z2=compute_Mlincomb_from_Mder(nep,λ,V,a)
        # println("should be zero:",norm(z2-z))
        return reshape(z,size(z,1))
    end

    function compute_Mlincomb_from_Mder(nep::NEP,λ::Number,V,a)
        #println("Using poor-man's compute_MM -> compute_Mlincomb")
        z=zeros(size(nep,1))
        for i=1:size(a,1)
            z+=compute_Mder(nep,λ,i-1)*(V[:,i]*a[i])
        end
        return z
    end


    function compute_resnorm(nep::NEP,λ,v)
        return norm(compute_Mlincomb(nep,λ,reshape(v,nep.n,1)))
    end


    function compute_rf(nep::NEP,x; y=x, target=0, λ0=target)
        # Ten steps of scalar Newton's method
        λ=λ0;
        for k=1:10
            z1=compute_Mlincomb(nep,λ,reshape(x,nep.n,1))
            z2=compute_Mlincomb(nep,λ,x*ones(1,2),a=[0,1])
            Δλ=-dot(y,z1)/dot(y,z2);
            λ=λ+Δλ
        end
        return λ
    end


    # Overload size function. Note: All NEPs must have a field: n.
    function size(nep::NEP,dim=-1)
        if (dim==-1)
            return (nep.n,nep.n)
        else
            return nep.n
        end
    end



    """
    Delay eigenvalue problem
"""
    type DEP <: NEP
        n::Integer
        A     # An array of matrices (full or sparse matrices)
        tauv::Array{Float64,1} # the delays
        function DEP(AA,tauv=[0,1.0])
            n=size(AA[1],1)
            this=new(n,AA,tauv);
            return this;
        end
    end

    """
    compute_Mder(nep::DEP,λ::Number,i::Integer=0)
 Compute the ith derivative of a DEP
"""
    function compute_Mder(nep::DEP,λ::Number,i::Integer=0)
        local M,I;
        if issparse(nep.A[1])
            M=spzeros(nep.n,nep.n)
            I=speye(nep.n,nep.n)
        else
            M=zeros(nep.n,nep.n)
            I=eye(nep.n,nep.n)        
        end
        if i==0; M=-λ*I;  end
        if i==1; M=-I; end
        for j=1:size(nep.A,1)
            M+=nep.A[j]*(exp(-nep.tauv[j]*λ)*(-nep.tauv[j])^i)
        end
        return M
    end



    """
    compute_Mder(nep::DEP,λ::Number,i::Integer=0)
 Compute the ith derivative of a DEP
"""
    function compute_MM(nep::DEP,S,V)
        Z=-V*S;
        for j=1:size(nep.A,1)
            Z+=nep.A[j]*V*expm(-nep.tauv[j]*S)
        end
        return Z
    end
    #

    """
    Polynomial eigenvalue problem
"""

    type PEP <: NEP
        n::Integer
        A::Array   # Monomial coefficients of PEP 
        function PEP(AA)
            n=size(AA[1],1)
            return new(n,AA)
        end
    end

    function compute_MM(nep::PEP,S,V)
        Z=zeros(size(V))
        Si=eye(size(S,1))
        for i=1:size(nep.A,1)
            Z+=nep.A[i]*V*Si;
            Si=Si*S;
        end
        return Z
    end


    function compute_Mder(nep::PEP,λ::Number,i::Integer=0)
        Z=zeros(size(nep,1),size(nep,1));
        for j=(i+1):size(nep.A,1)
            # Derivatives of monimials
            Z+= nep.A[j]*(λ^(j-i-1)*factorial(j-1)/factorial(j-i-1))
        end
        return Z
    end

    # In case an iterative method does not converge
    type NoConvergenceException <: Exception
        λ
        v
        errmeasure
        msg
    end


    # To slove linear systems
    type LinSolver
        solve::Function
        Afact
        function LinSolver(A)
            this=new()
            this.Afact=factorize(A)
            this.solve=function foo(x;tol=eps())
                return this.Afact\x
            end
            return this;
        end   
    end

    function jordan_matrix(n::Integer,λ::Number;T::Type=Float64)
        Z=λ*eye(T,n)+diagm(ones(T,n-1),1);
    end


    function default_errmeasure(nep::NEP)
        f=function (λ,v);
            compute_resnorm(nep,λ,v)
        end
        return f
    end

end  # End Module
