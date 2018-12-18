using .ccacKlondike
using Test

c1 = Card(4,2)
c2 = Card(5,1)
c3 = Card(7,4)
c4 = Card(5,3)
c5 = Card(12,1)
c6 = Card(13,3)
s1 = [Card(5,4) Card(4,3) Card(3,1)]
s2 = [Card(6,2)]
s3 = [Card(13,1) Card(12,2) Card(11,4) Card(10,3)]

## Testing if cards can be moved onto each other

@testset "Cards that can be Moved" begin
    @test canMoveCard(c1,c2)
    @test canMoveCard(c5,c6)
end

@testset "Cards that can't be Moved" begin
    @test !canMoveCard(c2,c1)
    @test !canMoveCard(c2,c3)
    @test !canMoveCard(c1,c4)
end

## Testing same colors

@testset "Same Color" begin 
    @test sameColor(c1,c6)
    @test sameColor(c2,c3)
end

@testset "Not Same Color" begin
    @test !sameColor(c1,c2)
    @test !sameColor(c3,c6)
end

## Testing the three card simulation

@testset "1/400 Chance" begin
    @test isapprox(.25,klondikeCarlo()[2];rtol=0.1)
end
