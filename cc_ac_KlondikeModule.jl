module ccacKlondike
    # Import statement; Only two external functions needed
    import Base.show, Random.shuffle!
    # Export statement
    export Card, KlondikeBoard, longestTableau, sameColor, canMoveCard, canMoveStack, move!, isPlayable, klondikeCarlo

    # Rank & Suit arrays for Base.show
    ranks = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"];
    suits = ["\u2660", "\u2661", "\u2662", "\u2663"]

    # Card struct with two constructors
    """
    # Description:
    Struct with two integers that represents a playing card.
    
    # Constructors:
    * Rank/Suit:
    ```julia
    julia> Card(1, 3)
    Ace♢
    ```

    * Ordinal:
    ```julia
    julia> Card(14)
    Ace♡
    ```
    """
    mutable struct Card
        rank::Integer
        suit::Integer
        # Rank/Suit constructor
        Card(r::Integer, s::Integer) = r in 1:13 && s in 1:4 ? new(r, s) : throw(ArgumentError("Rank and/or Suit out of bounds."))
        # Ordinal constructor
        Card(i::Integer) = i in 1:52 ?
            i % 13 == 0 ? new(13, div(i, 13)) : new(i % 13, div(i, 13) + 1) :
                throw(ArgumentError("The arguement must be an integer between 1 and 52."))
    end

    # printstyled() is used to make Heart & Diamond cards appear red
    Base.show(io::IO, c::Card) = printstyled(io, ranks[c.rank], suits[c.suit], color = c.suit % 3 == 1 ? :normal : :red)

    # K.B. struct (note the arrays of cards; there are many of them)
    """
    # Description:
    Struct with a myriad of Card arrays that function as a board for playing Klondike Solitaire. The arrays of Cards are of three types:

    * **Tableau**: A column of cards where the last indexed card is playable, any stack that ends at the last index. Each tableau has a special index of the form `iT#` that identifies which address contains the first visible card. At the start of a game, every `iT#` value is set to the length of the tableau.
    * **Stock**: Leftover cards after tableaus are dealt. 24 in total, the cards in the stock can be cycled through in order and drawn either once or thrice at a time.
    * **Foundation**: Initially empty, each foundation is tied to a certain suit, and cards must be placed in the foundation from Ace to King. Once all four foundations are full, the game is won.

    # Constructor:
    There is one constructor. It generates an array of all 52 playing cards, shuffles it, and then slices it into the fields of the struct.
    ```julia
    julia> KlondikeBoard()
    ```
    ```
    Stock:           Clubs: Spades: Hearts: Diamonds:
    6♢
    Tab. 1: Tab. 2: Tab. 3: Tab. 4: Tab. 5: Tab. 6: Tab. 7:
    King♠   [#??#]  [#??#]  [#??#]  [#??#]  [#??#]  [#??#]
            6♠      [#??#]  [#??#]  [#??#]  [#??#]  [#??#]
                    3♢     [#??#]  [#??#]  [#??#]  [#??#]
                            7♢     [#??#]  [#??#]  [#??#]
                                    8♣     [#??#]  [#??#]
                                            9♡    [#??#]
                                                    10♠
    ```
    """
    mutable struct KlondikeBoard
        # stock (leftover deck of cards after dealing initial tableaus)
        stock::Array{Card, 1}
        # foundations (where the cards end up in a finished game)
        fndC::Array{Card, 1}
        fndS::Array{Card, 1}
        fndH::Array{Card, 1}
        fndD::Array{Card, 1}
        # tableaus (main playing area, 21 cards are covered initially)
        t1::Array{Card, 1}
        t2::Array{Card, 1}
        t3::Array{Card, 1}
        t4::Array{Card, 1}
        t5::Array{Card, 1}
        t6::Array{Card, 1}
        t7::Array{Card, 1}
        # index of Stock (which card is currently playable from the stock)
        iStock::Integer
        # index of Tableau X (which card is the lowest in order that is face-up)
        iT1::Integer
        iT2::Integer
        iT3::Integer
        iT4::Integer
        iT5::Integer
        iT6::Integer
        iT7::Integer
        # debug flag for viewing all cards in tableaus
        invisible::Bool
    
        # Constructor (uses shuffle!() on an array of all cards and partitions them)
        function KlondikeBoard(invisible::Bool = true)
            local deck = collect(Card(i) for i = 1:52)
            shuffle!(deck)
            new(
                deck[29:52], # Stock
                Card[], Card[], Card[], Card[], # Foundations
                [deck[1]], deck[2:3], deck[4:6], deck[7:10], deck[11:15], deck[16:21], deck[22:28], # Tableaus
                1, # Stock Index
                1, 2, 3, 4, 5, 6, 7, # Tableau Visibility Indices
                invisible # Tableau Visibility Override (if false)
            )
        end
    end

    # Determines which tableau has the most cards of a given board
    "Determines the longest tableau (an array of Cards) in the given board `kb`."
    function longestTableau(kb::KlondikeBoard)
        local m = max(length(kb.t1), length(kb.t2), length(kb.t3), length(kb.t4), length(kb.t5), length(kb.t6), length(kb.t7))
        m == 1 ? kb.t1 : 
            m == 2 ? kb.t2 :
                m == 3 ? kb.t3 :
                    m == 4 ? kb.t4 :
                        m == 5 ? kb.t5 :
                            m == 6 ? kb.t6 :
                                kb.t7
    end

    # Displays the board as it would appear in real life
    function Base.show(io::IO, kb::KlondikeBoard)
        local i, t
        local cardBack = "[#??#]"
        local fnds = [kb.fndC, kb.fndS, kb.fndH, kb.fndD]
        local tableaus = [kb.t1, kb.t2, kb.t3, kb.t4, kb.t5, kb.t6, kb.t7]
        local tableauIndices = [kb.iT1, kb.iT2, kb.iT3, kb.iT4, kb.iT5, kb.iT6, kb.iT7]
    
        print(io)

        println("Stock:\t\t\tClubs:\tSpades:\tHearts:\tDiamonds:")
        print(kb.stock[kb.iStock])
        print("\t\t\t")
        for i = 1:4
            length(fnds[i]) > 0 ? print(last(fnds[i]), "\t") : print("\t")
        end
        println()

        for i = 1:7 print("Tab. ", string(i), ":\t") end
        println()
        for i = 1:length(longestTableau(kb))
            for t = 1:7
                i <= length(tableaus[t]) ?
                    i >= tableauIndices[t] || !kb.invisible ?
                        print(tableaus[t][i], "\t") :
                    printstyled(cardBack, "\t", color = :blue) :
                print("\t")
            end
            println()
        end
    end

    # Checks if two cars are the same color (red or black)
    "Returns `true` if the suits of `c1` and `c2` are such that they are the same color. Hearts and Diamonds are Red. Spades and Clubs are Black."
    function sameColor(c1::Card, c2::Card)
        local suitSum = c1.suit + c2.suit
        # The first case is 5 since 5 = 1 + 4 (black cards) = 3 + 2 (red cards)
        # Upon realization, the suitSum variable could be forgone entirely
        # TODO: Consider removing suitSum and rely on in-checks
        suitSum == 5 || c1.suit in (1, 4) && c2.suit in (1, 4) || c1.suit in (2, 3) && c2.suit in (2, 3)
    end

    # Checks if one card (src) can be moved onto the top of another (dest)
    "Returns `true` if the `srccard` can be legally moved onto the top of the `destcard`."
    function canMoveCard(srcCard::Card, destCard::Card)
        # A move is legal if the two cards involved are different colors,
        # and the src card is one less in rank than the dest card
        !sameColor(srcCard, destCard) && srcCard.rank + 1 == destCard.rank
    end

    # Checks if a stack of cards (array-slice) can be moved at all (is it in proper order?)
    "Returns `true` if the `stack` of cards is in legal order."
    function canMoveStack(stack::Array{Card, 1})
        local i
        for i = 1:length(stack) - 1
            !canMoveCard(stack[i + 1], stack[i]) ? (return false) : continue
        end
        true
    end

    # Moves a card from somewhere (src) in one location to another (dest)
    # Has five different classes of moves
    # Tableau    -->    Tableua
    # Tableau    --> Foundation
    # Foundation -->    Tableau
    # Stock      -->    Tableau
    # Stock      --> Foundation
    "Modifies a board `kb` by performing a legal move. There are five modes: `tt`, `tf`, `ft`, `st`, and `sf`."
    function move!(kb::KlondikeBoard, mode::String, src::Integer, dest::Integer, baseAddr::Integer = 1, elements::Integer = 1)
        function changeTI(kb::KlondikeBoard, index::Integer, value::Integer)
            index == 1 ? kb.iT1 = value :
            index == 2 ? kb.iT2 = value :
            index == 3 ? kb.iT3 = value :
            index == 4 ? kb.iT4 = value :
            index == 5 ? kb.iT5 = value :
            index == 6 ? kb.iT6 = value :
            kb.iT7 = value
        end
    
        fnds = [kb.fndC, kb.fndS, kb.fndH, kb.fndD]
        tableaus = [kb.t1, kb.t2, kb.t3, kb.t4, kb.t5, kb.t6, kb.t7]
        tableauIndices = [kb.iT1, kb.iT2, kb.iT3, kb.iT4, kb.iT5, kb.iT6, kb.iT7]

        if mode == "tt"
            local stack = Card[]
            if baseAddr >= tableauIndices[src] &&
                canMoveStack(tableaus[src][baseAddr:(baseAddr + elements - 1)]) &&
                canMoveCard(tableaus[src][baseAddr], last(tableaus[dest]))

                for i = 1:elements
                    push!(stack, pop!(tableaus[src]))
                end
                for i = 1:elements
                    push!(tableaus[dest], pop!(stack))
                end
            
                changeTI(kb, src, length(tableaus[src]) < tableauIndices[src] ? length(tableaus[src]) : tableauIndices[src])
            else
                throw(ErrorException("Error: Illegal move."))
            end
            
        elseif mode == "tf"
            # TODO: code this move case
        elseif mode == "ft"
            # TODO: code this move case
        elseif mode == "st"
            # TODO: code this move case
        elseif mode == "sf"
            # TODO: code this move case
        end
    end
    
    # Checks if there is a move possible in a current board
    "Returns `true` if the board under the given `drawMode` has a legal move possibly to be played."
    function isPlayable(kb::KlondikeBoard, drawMode::Integer = 1)
        tableaus = [kb.t1, kb.t2, kb.t3, kb.t4, kb.t5, kb.t6, kb.t7]
        local stockCards
        drawMode == 1 ? (stockCards = 1:24) : (stockCards = 3:3:24)
    
        for i = stockCards            
            for t in tableaus
                canMoveCard(kb.stock[i], last(t)) ? (return true) : continue
            end
            kb.stock[i].rank == 1 ? (return true) : continue
        end
    
        for tsrc in tableaus
            for tdest in tableaus
                tsrc != tdest && canMoveCard(last(tsrc), last(tdest)) ? (return true) : continue
            end
            last(tsrc).rank == 1 ? (return true) : continue
        end
    
        false
    end

    # Runs a Monte Carlo simulation of initial configurations of the board
    "Runs a Monte Carlo simulation of initial configurations of the Klondike board under a given `drawMode`."
    function klondikeCarlo(trials::Integer = 1_000_000, drawMode::Integer = 3)
        local unplayables = 0
        for i = 1:trials
            local kb = KlondikeBoard()
            isPlayable(kb, drawMode) ? continue : unplayables += 1
        end
        # Return a tuple with total unplayable games and percentage of unplayable games
        (unplayables, unplayables / trials * 100)
    end
end
