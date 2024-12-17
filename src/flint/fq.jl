###############################################################################
#
#   FqPolyRepFieldElem.jl : Flint finite fields
#
###############################################################################

###############################################################################
#
#   Type and parent object methods
#
###############################################################################

parent_type(::Type{FqPolyRepFieldElem}) = FqPolyRepField

elem_type(::Type{FqPolyRepField}) = FqPolyRepFieldElem

base_ring_type(::Type{FqPolyRepField}) = typeof(Union{})

base_ring(a::FqPolyRepField) = Union{}

parent(a::FqPolyRepFieldElem) = a.parent

is_domain_type(::Type{FqPolyRepFieldElem}) = true

###############################################################################
#
#   Basic manipulation
#
###############################################################################

function Base.hash(a::FqPolyRepFieldElem, h::UInt)
  b = 0xb310fb6ea97e1f1a%UInt
  z = ZZRingElem()
  for i in 0:degree(parent(a)) - 1
    @ccall libflint.fmpz_poly_get_coeff_fmpz(z::Ref{ZZRingElem}, a::Ref{FqPolyRepFieldElem}, i::Int)::Nothing
    b = xor(b, xor(hash(z, h), h))
    b = (b << 1) | (b >> (sizeof(Int)*8 - 1))
  end
  return b
end

@doc raw"""
    coeff(x::FqPolyRepFieldElem, n::Int)

Return the degree $n$ coefficient of the polynomial representing the given
finite field element.
"""
function coeff(x::FqPolyRepFieldElem, n::Int)
  n < 0 && throw(DomainError(n, "Index must be non-negative"))
  z = ZZRingElem()
  @ccall libflint.fmpz_poly_get_coeff_fmpz(z::Ref{ZZRingElem}, x::Ref{FqPolyRepFieldElem}, n::Int)::Nothing
  return z
end

zero(a::FqPolyRepField) = zero!(a())

one(a::FqPolyRepField) = one!(a())

@doc raw"""
    gen(a::FqPolyRepField)

Return the generator of the finite field. Note that this is only guaranteed
to be a multiplicative generator if the finite field is generated by a
Conway polynomial automatically.
"""
function gen(a::FqPolyRepField)
  d = a()
  @ccall libflint.fq_gen(d::Ref{FqPolyRepFieldElem}, a::Ref{FqPolyRepField})::Nothing
  return d
end

iszero(a::FqPolyRepFieldElem) = @ccall libflint.fq_is_zero(a::Ref{FqPolyRepFieldElem}, a.parent::Ref{FqPolyRepField})::Bool

isone(a::FqPolyRepFieldElem) = @ccall libflint.fq_is_one(a::Ref{FqPolyRepFieldElem}, a.parent::Ref{FqPolyRepField})::Bool

@doc raw"""
    is_gen(a::FqPolyRepFieldElem)

Return `true` if the given finite field element is the generator of the
finite field, otherwise return `false`.
"""
is_gen(a::FqPolyRepFieldElem) = a == gen(parent(a))

is_unit(a::FqPolyRepFieldElem) = !is_zero(a)

function characteristic(a::FqPolyRepField)
  d = ZZRingElem()
  @ccall libflint.__fq_ctx_prime(d::Ref{ZZRingElem}, a::Ref{FqPolyRepField})::Nothing
  return d
end

function order(a::FqPolyRepField)
  d = ZZRingElem()
  @ccall libflint.fq_ctx_order(d::Ref{ZZRingElem}, a::Ref{FqPolyRepField})::Nothing
  return d
end

@doc raw"""
    degree(a::FqPolyRepField)

Return the degree of the given finite field.
"""
function degree(a::FqPolyRepField)
  return @ccall libflint.fq_ctx_degree(a::Ref{FqPolyRepField})::Int
end

function deepcopy_internal(d::FqPolyRepFieldElem, dict::IdDict)
  z = FqPolyRepFieldElem(parent(d), d)
  return z
end

###############################################################################
#
#   Canonicalisation
#
###############################################################################

canonical_unit(x::FqPolyRepFieldElem) = x

###############################################################################
#
#   AbstractString I/O
#
###############################################################################

function expressify(a::FqPolyRepFieldElem; context = nothing)
  x = unsafe_string(reinterpret(Cstring, a.parent.var))
  d = degree(a.parent)

  sum = Expr(:call, :+)
  for k in (d - 1):-1:0
    c = coeff(a, k)
    if !iszero(c)
      xk = k < 1 ? 1 : k == 1 ? x : Expr(:call, :^, x, k)
      if isone(c)
        push!(sum.args, Expr(:call, :*, xk))
      else
        push!(sum.args, Expr(:call, :*, expressify(c, context = context), xk))
      end
    end
  end
  return sum
end

show(io::IO, a::FqPolyRepFieldElem) = print(io, AbstractAlgebra.obj_to_string(a, context = io))

function show(io::IO, a::FqPolyRepField)
  @show_name(io, a)
  @show_special(io, a)
  if is_terse(io)
    io = pretty(io)
    print(io, LowercaseOff(), "GF($(characteristic(a))^$(degree(a)))")
  else
    print(io, "Finite field of degree ", degree(a))
    print(io, " over GF(", characteristic(a),")")
  end
end

###############################################################################
#
#   Unary operations
#
###############################################################################

-(x::FqPolyRepFieldElem) = neg!(parent(x)(), x)

###############################################################################
#
#   Binary operations
#
###############################################################################

function +(x::FqPolyRepFieldElem, y::FqPolyRepFieldElem)
  check_parent(x, y)
  z = parent(y)()
  @ccall libflint.fq_add(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, y.parent::Ref{FqPolyRepField})::Nothing
  return z
end

function -(x::FqPolyRepFieldElem, y::FqPolyRepFieldElem)
  check_parent(x, y)
  z = parent(y)()
  @ccall libflint.fq_sub(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, y.parent::Ref{FqPolyRepField})::Nothing
  return z
end

function *(x::FqPolyRepFieldElem, y::FqPolyRepFieldElem)
  check_parent(x, y)
  z = parent(y)()
  @ccall libflint.fq_mul(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, y.parent::Ref{FqPolyRepField})::Nothing
  return z
end

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

function *(x::Int, y::FqPolyRepFieldElem)
  z = parent(y)()
  @ccall libflint.fq_mul_si(z::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, x::Int, y.parent::Ref{FqPolyRepField})::Nothing
  return z
end

*(x::Integer, y::FqPolyRepFieldElem) = ZZRingElem(x)*y

*(x::FqPolyRepFieldElem, y::Integer) = y*x

function *(x::ZZRingElem, y::FqPolyRepFieldElem)
  z = parent(y)()
  @ccall libflint.fq_mul_fmpz(z::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, x::Ref{ZZRingElem}, y.parent::Ref{FqPolyRepField})::Nothing
  return z
end

*(x::FqPolyRepFieldElem, y::ZZRingElem) = y*x

+(x::FqPolyRepFieldElem, y::Integer) = x + parent(x)(y)

+(x::Integer, y::FqPolyRepFieldElem) = y + x

+(x::FqPolyRepFieldElem, y::ZZRingElem) = x + parent(x)(y)

+(x::ZZRingElem, y::FqPolyRepFieldElem) = y + x

-(x::FqPolyRepFieldElem, y::Integer) = x - parent(x)(y)

-(x::Integer, y::FqPolyRepFieldElem) = parent(y)(x) - y

-(x::FqPolyRepFieldElem, y::ZZRingElem) = x - parent(x)(y)

-(x::ZZRingElem, y::FqPolyRepFieldElem) = parent(y)(x) - y

###############################################################################
#
#   Powering
#
###############################################################################

function ^(x::FqPolyRepFieldElem, y::Int)
  if y < 0
    x = inv(x)
    y = -y
  end
  z = parent(x)()
  @ccall libflint.fq_pow_ui(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, y::Int, x.parent::Ref{FqPolyRepField})::Nothing
  return z
end

function ^(x::FqPolyRepFieldElem, y::ZZRingElem)
  if y < 0
    x = inv(x)
    y = -y
  end
  z = parent(x)()
  @ccall libflint.fq_pow(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, y::Ref{ZZRingElem}, x.parent::Ref{FqPolyRepField})::Nothing
  return z
end

###############################################################################
#
#   Comparison
#
###############################################################################

function ==(x::FqPolyRepFieldElem, y::FqPolyRepFieldElem)
  check_parent(x, y)
  @ccall libflint.fq_equal(x::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, y.parent::Ref{FqPolyRepField})::Bool
end

###############################################################################
#
#   Ad hoc comparison
#
###############################################################################

==(x::FqPolyRepFieldElem, y::Integer) = x == parent(x)(y)

==(x::FqPolyRepFieldElem, y::ZZRingElem) = x == parent(x)(y)

==(x::Integer, y::FqPolyRepFieldElem) = parent(y)(x) == y

==(x::ZZRingElem, y::FqPolyRepFieldElem) = parent(y)(x) == y

###############################################################################
#
#   Exact division
#
###############################################################################

function divexact(x::FqPolyRepFieldElem, y::FqPolyRepFieldElem; check::Bool=true)
  check_parent(x, y)
  iszero(y) && throw(DivideError())
  z = parent(y)()
  @ccall libflint.fq_div(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, y.parent::Ref{FqPolyRepField})::Nothing
  return z
end

function divides(a::FqPolyRepFieldElem, b::FqPolyRepFieldElem)
  if iszero(a)
    return true, zero(parent(a))
  end
  if iszero(b)
    return false, zero(parent(a))
  end
  return true, divexact(a, b)
end

###############################################################################
#
#   Ad hoc exact division
#
###############################################################################

divexact(x::FqPolyRepFieldElem, y::Integer; check::Bool=true) = divexact(x, parent(x)(y); check=check)

divexact(x::FqPolyRepFieldElem, y::ZZRingElem; check::Bool=true) = divexact(x, parent(x)(y); check=check)

divexact(x::Integer, y::FqPolyRepFieldElem; check::Bool=true) = divexact(parent(y)(x), y; check=check)

divexact(x::ZZRingElem, y::FqPolyRepFieldElem; check::Bool=true) = divexact(parent(y)(x), y; check=check)

###############################################################################
#
#   Inversion
#
###############################################################################

function inv(x::FqPolyRepFieldElem)
  iszero(x) && throw(DivideError())
  z = parent(x)()
  @ccall libflint.fq_inv(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, x.parent::Ref{FqPolyRepField})::Nothing
  return z
end

###############################################################################
#
#   Special functions
#
###############################################################################

function sqrt(x::FqPolyRepFieldElem; check::Bool=true)
  z = parent(x)()
  res = Bool(@ccall libflint.fq_sqrt(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, x.parent::Ref{FqPolyRepField})::Cint)
  check && !res && error("Not a square")
  return z
end

function is_square(x::FqPolyRepFieldElem)
  return Bool(@ccall libflint.fq_is_square(x::Ref{FqPolyRepFieldElem}, x.parent::Ref{FqPolyRepField})::Cint)
end

function is_square_with_sqrt(x::FqPolyRepFieldElem)
  z = parent(x)()
  flag = @ccall libflint.fq_sqrt(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, x.parent::Ref{FqPolyRepField})::Cint
  return (Bool(flag), z)
end

@doc raw"""
    pth_root(x::FqPolyRepFieldElem)

Return the $p$-th root of $x$ in the finite field of characteristic $p$. This
is the inverse operation to the Frobenius map $\sigma_p$.
"""
function pth_root(x::FqPolyRepFieldElem)
  z = parent(x)()
  @ccall libflint.fq_pth_root(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, x.parent::Ref{FqPolyRepField})::Nothing
  return z
end

@doc raw"""
    tr(x::FqPolyRepFieldElem)

Return the trace of $x$. This is an element of $\mathbb{F}_p$, but the value returned
is this value embedded in the original finite field.
"""
function tr(x::FqPolyRepFieldElem)
  z = ZZRingElem()
  @ccall libflint.fq_trace(z::Ref{ZZRingElem}, x::Ref{FqPolyRepFieldElem}, x.parent::Ref{FqPolyRepField})::Nothing
  return parent(x)(z)
end

@doc raw"""
    norm(x::FqPolyRepFieldElem)

Return the norm of $x$. This is an element of $\mathbb{F}_p$, but the value returned
is this value embedded in the original finite field.
"""
function norm(x::FqPolyRepFieldElem)
  z = ZZRingElem()
  @ccall libflint.fq_norm(z::Ref{ZZRingElem}, x::Ref{FqPolyRepFieldElem}, x.parent::Ref{FqPolyRepField})::Nothing
  return parent(x)(z)
end

@doc raw"""
    frobenius(x::FqPolyRepFieldElem, n = 1)

Return the iterated Frobenius $\sigma_p^n(x)$ where $\sigma_p$ is the
Frobenius map sending the element $a$ to $a^p$ in the finite field of
characteristic $p$. By default the Frobenius map is applied $n = 1$ times if
$n$ is not specified.
"""
function frobenius(x::FqPolyRepFieldElem, n = 1)
  z = parent(x)()
  @ccall libflint.fq_frobenius(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, n::Int, x.parent::Ref{FqPolyRepField})::Nothing
  return z
end

###############################################################################
#
#   Lift
#
###############################################################################

@doc raw"""
    lift(R::FpPolyRing, x::FqPolyRepFieldElem)

Lift the finite field element `x` to a polynomial over the prime field.
"""
function lift(R::FpPolyRing, x::FqPolyRepFieldElem)
  c = R()
  @ccall libflint.fq_get_fmpz_mod_poly(c::Ref{FpPolyRingElem}, x::Ref{FqPolyRepFieldElem}, parent(x)::Ref{FqPolyRepField})::Nothing
  return c
end

###############################################################################
#
#   Unsafe functions
#
###############################################################################

function zero!(z::FqPolyRepFieldElem)
  @ccall libflint.fq_zero(z::Ref{FqPolyRepFieldElem}, z.parent::Ref{FqPolyRepField})::Nothing
  return z
end

function one!(z::FqPolyRepFieldElem)
  @ccall libflint.fq_one(z::Ref{FqPolyRepFieldElem}, z.parent::Ref{FqPolyRepField})::Nothing
  return z
end

function neg!(z::FqPolyRepFieldElem, a::FqPolyRepFieldElem)
  @ccall libflint.fq_neg(z::Ref{FqPolyRepFieldElem}, a::Ref{FqPolyRepFieldElem}, a.parent::Ref{FqPolyRepField})::Nothing
  return z
end

#

function set!(z::FqPolyRepFieldElem, a::FqPolyRepFieldElemOrPtr)
  @ccall libflint.fq_set(z::Ref{FqPolyRepFieldElem}, a::Ref{FqPolyRepFieldElem}, parent(z)::Ref{FqPolyRepField})::Nothing
end

function set!(z::FqPolyRepFieldElem, a::Int)
  @ccall libflint.fq_set_si(z::Ref{FqPolyRepFieldElem}, a::Int, parent(z)::Ref{FqPolyRepField})::Nothing
end

function set!(z::FqPolyRepFieldElem, a::UInt)
  @ccall libflint.fq_set_ui(z::Ref{FqPolyRepFieldElem}, a::UInt, parent(z)::Ref{FqPolyRepField})::Nothing
end

function set!(z::FqPolyRepFieldElem, a::ZZRingElemOrPtr)
  @ccall libflint.fq_set_fmpz(z::Ref{FqPolyRepFieldElem}, a::Ref{ZZRingElem}, parent(z)::Ref{FqPolyRepField})::Nothing
end

set!(z::FqPolyRepFieldElem, a::Integer) = set!(z, flintify(a))

function set!(z::FqPolyRepFieldElem, a::ZZPolyRingElemOrPtr)
  @ccall libflint.fq_set_fmpz_poly(z::Ref{FqPolyRepFieldElem}, a::Ref{ZZPolyRingElem}, parent(z)::Ref{FqPolyRepField})::Nothing
end

function set!(z::FqPolyRepFieldElem, a::ZZModPolyRingElemOrPtr)
  @ccall libflint.fq_set_fmpz_mod_poly(z::Ref{FqPolyRepFieldElem}, a::Ref{ZZModPolyRingElem}, parent(z)::Ref{FqPolyRepField})::Nothing
end

function set!(z::FqPolyRepFieldElem, a::FpPolyRingElemOrPtr)
  @ccall libflint.fq_set_fmpz_mod_poly(z::Ref{FqPolyRepFieldElem}, a::Ref{FpPolyRingElem}, parent(z)::Ref{FqPolyRepField})::Nothing
end

#

function mul!(z::FqPolyRepFieldElem, x::FqPolyRepFieldElem, y::FqPolyRepFieldElem)
  @ccall libflint.fq_mul(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, y.parent::Ref{FqPolyRepField})::Nothing
  return z
end

function add!(z::FqPolyRepFieldElem, x::FqPolyRepFieldElem, y::FqPolyRepFieldElem)
  @ccall libflint.fq_add(z::Ref{FqPolyRepFieldElem}, x::Ref{FqPolyRepFieldElem}, y::Ref{FqPolyRepFieldElem}, x.parent::Ref{FqPolyRepField})::Nothing
  return z
end

################################################################################
#
#   FqPolyRepField Modulus
#
################################################################################

@doc raw"""
    modulus(k::FqPolyRepField, var::VarName=:T)

Return the modulus defining the finite field $k$.
"""
function modulus(k::FqPolyRepField, var::VarName=:T)
  p = characteristic(k)
  Q = polynomial(Native.GF(p), [], Symbol(var))
  P = @ccall libflint.fq_ctx_modulus(k::Ref{FqPolyRepField})::Ref{FpPolyRingElem}
  @ccall libflint.fmpz_mod_poly_set(Q::Ref{FpPolyRingElem}, P::Ref{FpPolyRingElem}, base_ring(Q)::Ref{FpField})::Nothing

  return Q
end

function defining_polynomial(k::FqPolyRepField)
  F = FpField(characteristic(k))
  Fx, = polynomial_ring(F, "x", cached = false)
  return defining_polynomial(Fx, k)
end

function defining_polynomial(R::FpPolyRing, k::FqPolyRepField)
  Q = R()
  GC.@preserve k begin
    P = @ccall libflint.fq_ctx_modulus(k::Ref{FqPolyRepField})::Ptr{FpPolyRingElem}
    @ccall libflint.fmpz_mod_poly_set(Q::Ref{FpPolyRingElem}, P::Ptr{FpPolyRingElem})::Nothing
  end
  return Q
end

###############################################################################
#
#   Promotions
#
###############################################################################

promote_rule(::Type{FqPolyRepFieldElem}, ::Type{T}) where {T <: Integer} = FqPolyRepFieldElem

promote_rule(::Type{FqPolyRepFieldElem}, ::Type{ZZRingElem}) = FqPolyRepFieldElem

promote_rule(::Type{FqPolyRepFieldElem}, ::Type{FpFieldElem}) = FqPolyRepFieldElem

###############################################################################
#
#   Parent object call overload
#
###############################################################################

function (a::FqPolyRepField)()
  z = FqPolyRepFieldElem(a)
  return z
end

(a::FqPolyRepField)(b::Integer) = a(ZZRingElem(b))

function (a::FqPolyRepField)(b::Int)
  z = FqPolyRepFieldElem(a, b)
  z.parent = a
  return z
end

function (a::FqPolyRepField)(b::ZZRingElem)
  z = FqPolyRepFieldElem(a, b)
  z.parent = a
  return z
end

function (a::FqPolyRepField)(b::FqPolyRepFieldElem)
  k = parent(b)
  da = degree(a)
  dk = degree(k)
  if k == a
    return b
  elseif dk < da
    da % dk != 0 && error("Coercion impossible")
    f = embed(k, a)
    return f(b)
  else
    dk % da != 0 && error("Coercion impossible")
    f = preimage_map(a, k)
    return f(b)
  end
end

function (A::FqPolyRepField)(x::FpFieldElem)
  @assert characteristic(A) == characteristic(parent(x))
  return A(lift(x))
end

function (a::FqPolyRepField)(b::Vector{<:IntegerUnion})
  da = degree(a)
  db = length(b)
  da == db || error("Coercion impossible")
  F = Native.GF(characteristic(a), cached = false)
  return FqPolyRepFieldElem(a, polynomial(F, b))
end

function (k::FqPolyRepField)(a::QQFieldElem)
  return k(numerator(a)) // k(denominator(a))
end

###############################################################################
#
#   Minimal polynomial and characteristic polynomial
#
###############################################################################

function minpoly(a::FqPolyRepFieldElem)
  Fp = Native.GF(characteristic(parent(a)), cached=false)
  Rx, _ = polynomial_ring(Fp, cached=false)
  return minpoly(Rx, a)
end

function minpoly(Rx::FpPolyRing, a::FqPolyRepFieldElem)
  @assert characteristic(base_ring(Rx)) == characteristic(parent(a))
  c = [a]
  fa = frobenius(a)
  while !(fa in c)
    push!(c, fa)
    fa = frobenius(fa)
  end
  St = polynomial_ring(parent(a), cached=false)[1]
  f = prod(gen(St) - x for x = c; init=one(St))
  g = Rx()
  for i = 0:degree(f)
    setcoeff!(g, i, coeff(coeff(f, i), 0))
  end
  return g
end

function charpoly(a::FqPolyRepFieldElem)
  Fp = Native.GF(characteristic(parent(a)), cached=false)
  Rx, _ = polynomial_ring(Fp, cached=false)
  return charpoly(Rx, a)
end

function charpoly(Rx::FpPolyRing, a::FqPolyRepFieldElem)
  g = minpoly(Rx, a)
  return g^div(degree(parent(a)), degree(g))
end
