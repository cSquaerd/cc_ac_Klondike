module ccacKlondike
    import Base.show, Random.shuffle!, StatsBase.counts
    export Card

    ranks = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"];
    suits = ["\u2660", "\u2661", "\u2662", "\u2663"]

    mutable struct Card
        rank::Integer
        suit::Integer
        Card(r::Integer, s::Integer) = r in 1:13 && s in 1:4 ? new(r, s) : throw(ArgumentError("Rank and/or Suit out of bounds."))
        Card(i::Integer) = i in 1:52 ?
            i % 13 == 0 ? new(13, div(i, 13)) : new(i % 13, div(i, 13) + 1) :
                throw(ArgumentError("The arguement must be an integer between 1 and 52."))
                
    end

    Base.show(io::IO, c::Card) = print(io, string(ranks[c.rank], " of ", suits[c.suit]))
end