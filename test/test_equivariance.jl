using EquivariantModels
using StaticArrays
using Test
using ACEbase.Testing: print_tf
using Rotations, WignerD, BlockDiagonals
using LinearAlgebra

@info("Testing single vector case")
totdeg = 6
ν = 2

for L = 0:4
   local F, luxchain, ps, st
   luxchain, ps, st = luxchain_constructor(totdeg,ν,L;islong = false)
   F(X) = luxchain(X, ps, st)[1]
   
   @info("Tesing L = $L O(3) equivariance")
   for _ = 1:30
      local X, θ, Q, QX
      X = [ @SVector(rand(3)) for i in 1:10 ]
      θ = rand() * 2pi
      Q = RotXYZ(0, 0, θ)
      # Q = rand_rot()
      QX = [SVector{3}(x) for x in Ref(Q) .* X]
      D = wignerD(L, 0, 0, θ)
      if L == 0
         print_tf(@test F(X) ≈ F(QX))
      else
         print_tf(@test F(X) ≈ Ref(D) .* F(QX))
      end
   end
   println()
end

@info("Testing SYYVector case")
totdeg = 6
ν = 2
L = 4
luxchain, ps, st = luxchain_constructor(totdeg,ν,L;islong = true)
local F
F(X) = luxchain(X, ps, st)[1]
@info("Tesing L = $L O(3) full equivariance")

for ntest = 1:20
   local X, θ, Q, QX
   X = [ @SVector(rand(3)) for i in 1:10 ]
   θ = rand() * 2pi
   Q = RotXYZ(0, 0, θ)
   QX = [SVector{3}(x) for x in Ref(Q) .* X]
   D = BlockDiagonal([ wignerD(l, 0, 0, θ) for l = 0:L] )
   
   print_tf(@test Ref(D) .* F(QX) ≈ F(X))
end
println()

## equivariant blocks
@info("Testing the chain that generates several equivariant blocks from a long vector")
totdeg = 6
ν = 2
L = 4
luxchain, ps, st = equivariant_luxchain_constructor(totdeg,ν,L)
F(X) = luxchain(X, ps, st)[1]

# A small comparison - long vector does give us some redundent basis...

@info("Equivariance test")
l1l2set = [(l1,l2) for l1 = 0:L for l2 = 0:L-l1]
for ntest = 1:10
   local X, θ, Q, QX
   X = [ @SVector(rand(3)) for i in 1:10 ]
   θ = rand() * 2pi
   Q = RotXYZ(0, 0, θ)
   QX = [SVector{3}(x) for x in Ref(Q) .* X]

   for (i,(l1,l2)) in enumerate(l1l2set)
      D1 = wignerD(l1, 0, 0, θ)
      D2 = wignerD(l2, 0, 0, θ)
      if F(X)[i] |> length ≠ 0
         print_tf(@test norm(Ref(D1') .* F(X)[i] .* Ref(D2) - F(QX)[i]) < 1e-8) 
      end
   end
end
println()

## A second way - construct B^0, B^1, ..., B^L first
@info("Testing the chain that generates all the B bases")
totdeg = 6
ν = 2
L = 4
luxchain, ps, st = luxchain_constructor_multioutput(totdeg,ν,L)
F(X) = luxchain(X, ps, st)[1]

for ntest = 1:10
   local X, θ, Q, QX
   X = [ @SVector(rand(3)) for i in 1:10 ]
   θ = rand() * 2pi
   Q = RotXYZ(0, 0, θ)
   QX = [SVector{3}(x) for x in Ref(Q) .* X]
   
   print_tf(@test F(X)[1] ≈ F(QX)[1])

   for l = 2:L
      D = wignerD(l-1, 0, 0, θ)
      print_tf(@test norm.(Ref(D') .* F(X)[l] - F(QX)[l]) |> norm <1e-8)
   end
end
println()

@info("Consistency check")
totdeg = 6
ν = 2
L = 4
luxchain, ps, st = luxchain_constructor_multioutput(totdeg,ν,L);
F(X) = luxchain(X, ps, st)[1]

for l = 0:4
   @info("Consistency check for L = $l")
   local FF, luxchain, ps, st
   luxchain, ps, st = luxchain_constructor(totdeg,ν,l;islong = false)
   FF(X) = luxchain(X, ps, st)[1]
   
   for ntest = 1:20
      X = [ @SVector(rand(3)) for i in 1:10 ]
      print_tf(@test F(X)[l+1] == FF(X))
   end
   println()
end

@info("Testing the equivariance of the second way of constructing equivariant bases")
totdeg = 6
ν = 1
L = 4
luxchain, ps, st = EquivariantModels.equivariant_luxchain_constructor_new(totdeg,ν,L);
F(X) = luxchain(X, ps, st)[1]

for ntest = 1:10
   local X, θ, Q, QX
   X = [ @SVector(rand(3)) for i in 1:10 ]
   θ = rand() * 2pi
   Q = RotXYZ(0, 0, θ)
   QX = [SVector{3}(x) for x in Ref(Q) .* X]

   for i = 1:length(F(X))
      l1,l2 = Int.(size(F(X)[i][1]).-1)./2
      D1 = wignerD(l1, 0, 0, θ)
      D2 = wignerD(l2, 0, 0, θ)
      print_tf(@test Ref(D1') .* F(X)[i] .* Ref(D2) - F(QX)[i] |> norm < 1e-12)
   end
end
println()
