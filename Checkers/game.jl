default_state = Int64[-1 -1 -1 -1; -1 -1 -1 -1;
                      -1 -1 -1 -1;  0  0  0  0;
                       0  0  0  0;  1  1  1  1;
                       1  1  1  1;  1  1  1  1]

mutable struct Game
    states::Array{Int64, 2}
    pID::Int64
    count40::Int64
    winner::Union{Int64, Void}
    men::Array{Int64, 1}
    lastAction::Tuple{Int64,Int64,Vararg{Int64,N} where N}
    hopMove::Bool

    function Game()
        states = copy(default_state)
        return new(states, 0, 0, nothing, Int64[12, 12], (0, 0), false)
    end

    function Game(::Bool)
        return new()
    end
end

function restart(g::Game, state::Array{Int64, 2}=default_state)
    g.states = copy(state)
    g.pID = 0
    g.count40 = 0
    g.winner = nothing
    g.men[1] = 12
    g.men[2] = 12
    g.lastAction = (0, 0)
    g.hopMove = false

    nothing
end

function makecopy(g::Game)
    gcpy = Game(false)
    gcpy.states = copy(g.states)
    gcpy.pID = g.pID
    gcpy.count40 = g.count40
    gcpy.winner = g.winner
    gcpy.men = copy(g.men)
    gcpy.lastAction = g.lastAction
    gcpy.hopMove = g.hopMove

    return gcpy
end

function decreaseMen(g::Game, opponent::Int64)
    g.men[opponent + 1] -= 1
end

Base.show(io::IO, g::Game) = print(io, "Checkers<8x8>")

## deprecated
# function updatePlayerID(g::Game)
#     if g.hopMove
#         g.pID = div((-sign(g.states[g.lastAction[2]]) + 1), 2)
#     else
#         g.pID = div((sign(g.states[g.lastAction[2]]) + 1), 2)
#     end
# end

# Move without using getValidMoves() function
# Never use getValidMoves() and then justMove!
function justMove(g::Game, action::Tuple{Int64,Int64,Vararg{Int64,N} where N})
    if length(g.lastAction) == 3 && g.lastAction[2] != action[1]
        g.pID = 1 - g.pID # or g.pID = id_gracza_na_pozycji_board[action[1]]
    end
    g.states[action[2]] = (action[2] in kingStrip ? 2sign(g.states[action[1]]) : g.states[action[1]])
    g.states[action[1]] = 0
    if length(action) == 2 # normal move
        @assert sign(g.states[action[2]]) == (g.pID == 0 ? 1 : -1) "Wrong player move"
        g.pID = 1 - g.pID
        g.hopMove = false
    else # if length(action) == 3 # attacking move
        @assert sign(g.states[action[2]]) == (g.pID == 0 ? 1 : -1) "Wrong player move. Action: $(action). $(g.states[action[2]]) ≢ $(g.pID == 0 ? 1 : -1)"
        decreaseMen(g, 1 - g.pID)
        g.states[action[3]] = 0
        g.count40 = -1
        g.hopMove = true
    end
    g.count40 += 1
    g.lastAction = action
end

# Use getValidMoves() before moving!
function move(g::Game, action::Tuple{Int64,Int64,Vararg{Int64,N} where N})
    g.states[action[2]] = (action[2] in kingStrip ? 2sign(g.states[action[1]]) : g.states[action[1]])
    g.states[action[1]] = 0
    if length(action) == 2 # normal move
        @assert sign(g.states[action[2]]) == (g.pID == 0 ? 1 : -1) "Wrong player move"
        g.pID = 1 - g.pID
        g.hopMove = false
    else # if length(action) == 3 # attacking move
        @assert sign(g.states[action[2]]) == (g.pID == 0 ? 1 : -1) "Wrong player move. Action: $(action). $(g.states[action[2]]) ≢ $(g.pID == 0 ? 1 : -1)"
        decreaseMen(g, 1 - g.pID)
        g.states[action[3]] = 0
        g.count40 = -1
        g.hopMove = true
    end
    g.count40 += 1
    g.lastAction = action
end

function canMove(g::Game)
    men = g.men
    if men[2] == 0
        g.winner = 1
        return false
    end
    if men[1] == 0
        g.winner = -1
        return false
    end
    if g.count40 > 39
        g.winner = 0
        return false
    end
    if g.winner != nothing
        return false
    end
    return true
end

# Kings' strip
kingStrip = (1, 9, 17, 25, 8, 16, 24, 32)

# D_HD_U_HU
actions = Array{Tuple,1}[
        [(10, 2), (11,), Tuple{}(), Tuple{}()],
        [(3,), (12,), (1,), Tuple{}()],
        [(12, 4), (13,), (10, 2), (9,)],
        [(5,), (14,), (3,), (10,)],
        [(14, 6), (15,), (12, 4), (11,)],
        [(7,), (16,), (5,), (12,)],
        [(8, 16), Tuple{}(), (14, 6), (13,)],
        [Tuple{}(), Tuple{}(), (7,), (14,)],
        [(10, 18), (3, 19), Tuple{}(), Tuple{}()],
        [(3, 11), (4, 20), (1, 9), Tuple{}()],
        [(12, 20), (5, 21), (10, 18), (1, 17)],
        [(5, 13), (6, 22), (3, 11), (2, 18)],
        [(14, 22), (7, 23), (12, 20), (3, 19)],
        [(7, 15), (8, 24), (5, 13), (4, 20)],
        [(16, 24), Tuple{}(), (14, 22), (5, 21)],
        [Tuple{}(), Tuple{}(), (7, 15), (6, 22)],
        [(18, 26), (11, 27), Tuple{}(), Tuple{}()],
        [(11, 19), (12, 28), (9, 17), Tuple{}()],
        [(20, 28), (13, 29), (18, 26), (9, 25)],
        [(13, 21), (14, 30), (11, 19), (10, 26)],
        [(22, 30), (15, 31), (20, 28), (11, 27)],
        [(15, 23), (16, 32), (13, 21), (12, 28)],
        [(24, 32), Tuple{}(), (22, 30), (13, 29)],
        [Tuple{}(), Tuple{}(), (15, 23), (14, 30)],
        [(26,), (19,), Tuple{}(), Tuple{}()],
        [(19, 27), (20,), (17, 25), Tuple{}()],
        [(28,), (21,), (26,), (17,)],
        [(21, 29), (22,), (19, 27), (18,)],
        [(30,), (23,), (28,), (19,)],
        [(23, 31), (24,), (21, 29), (20,)],
        [(32,), Tuple{}(), (30,), (21,)],
        [Tuple{}(), Tuple{}(), (23, 31), (22,)]
]

function trimIfAttack(moves)
    if length(moves) > 0 && length(moves[end]) == 3
        filter!(x -> (length(x) == 3), moves)
    end
end

function playerID(value::Int64)
    (value > 0) && return 0
    (value < 0) && return 1
    # @assert !(value == 0) "PlayerID of value 0"
    return 9
end

function getValidMoves(g::Game)
    valid = Array{Tuple{Int64,Int64,Vararg{Int64,N} where N},1}()
    # na koncu zamien player i board na g.* zeby "przyspieszyc"
    # to samo zrob z `A` jako actions[i] i moze dla `i` też
    player = g.pID
    board = g.states
    hop = false
    # actions -> [Down, HopDown, Up, HopUp]
    if g.hopMove # player has to hop or pass
        i = g.lastAction[2]
        if player == 0
            A = actions[i]
            for i4 in 1:length(A[4])
                if board[A[4][i4]] == 0 && board[A[3][i4]] < 0
                    push!(valid, (i, A[4][i4], A[3][i4]))
                end
            end # for i4
            if board[i] > 1
                for i2 in 1:length(A[2])
                    if board[A[2][i2]] == 0 && board[A[1][i2]] < 0
                        push!(valid, (i, A[2][i2], A[1][i2]))
                    end
                end # for i2
            end # if ... > 1
        else # if player == 1
            A = actions[i]
            for i2 in 1:length(A[2])
                if board[A[2][i2]] == 0 && board[A[1][i2]] > 0
                    push!(valid, (i, A[2][i2], A[1][i2]))
                end
            end # for i2
            if board[i] < -1
                for i4 in 1:length(A[4])
                    if board[A[4][i4]] == 0 && board[A[3][i4]] > 0
                        push!(valid, (i, A[4][i4], A[3][i4]))
                    end
                end # for i4
            end # if ... < -1
        end
        if length(valid) == 0
            g.hopMove = false
            g.pID = 1 - g.pID
        end
    end # player can't second-hop
    if !g.hopMove # check again whether it's a different player
        if player == 0
            for i in 1:length(board)
                (board[i] <= 0) && continue
                A = actions[i]
                for i4 in 1:length(A[4])
                    if board[A[4][i4]] == 0 && board[A[3][i4]] < 0
                        push!(valid, (i, A[4][i4], A[3][i4]))
                        hop = true
                    end
                end # for i4
                if board[i] > 1
                    for i2 in 1:length(A[2])
                        if board[A[2][i2]] == 0 && board[A[1][i2]] < 0
                            push!(valid, (i, A[2][i2], A[1][i2]))
                            hop = true
                        end
                    end # for i2
                end
                if !hop
                    for i3 in 1:length(A[3])
                        if board[A[3][i3]] == 0
                            push!(valid, (i, A[3][i3]))
                        end
                    end # for i3
                    if board[i] > 1
                        for i1 in 1:length(A[1])
                            if board[A[1][i1]] == 0
                                push!(valid, (i, A[1][i1]))
                            end
                        end # for i1
                    end
                end
            end
            trimIfAttack(valid)
        else # if player == 1
            for i in 1:length(board)
                (board[i] >= 0) && continue
                A = actions[i]
                for i2 in 1:length(A[2])
                    if board[A[2][i2]] == 0 && board[A[1][i2]] > 0
                        push!(valid, (i, A[2][i2], A[1][i2]))
                        hop = true
                    end
                end # for i2
                if board[i] > 1
                    for i4 in 1:length(A[4])
                        if board[A[4][i4]] == 0 && board[A[3][i4]] > 0
                            push!(valid, (i, A[4][i4], A[3][i4]))
                            hop = true
                        end
                    end # for i4
                end
                if !hop
                    for i1 in 1:length(A[1])
                        if board[A[1][i1]] == 0
                            push!(valid, (i, A[1][i1]))
                        end
                    end # for i1
                    if board[i] > 1
                        for i3 in 1:length(A[3])
                            if board[A[3][i3]] == 0
                                push!(valid, (i, A[3][i3]))
                            end
                        end # for i3
                    end
                end
            end
            trimIfAttack(valid)
        end # if player
    end # if finished filling valid moves
    @assert length(valid) > 0 "Check if valid can be empty, if so --- remove assertion"
    if length(valid) == 0
        g.winner = g.pID == 0 ? -1 : 1
    end
    return valid
end

# function getValidMoves(g::Game)
#     # PLAYER MUST HOP
#     player = g.pID
#     valid = Array{Tuple{Int64,Int64,Vararg{Int64,N} where N},1}()
#     board = g.states
#     if player == 1
#         hop = false
#         for i in 1:length(board)
#             if board[i] == 0
#                 # D_HD_U_HU
#                 A = actions[i]
#                 for i4 in 1:length(A[4])
#                     if board[A[4][i4]] < 0 && board[A[3][i4]] > 0
#                         push!(valid, (A[4][i4], i, A[3][i4]))
#                         hop = true
#                     end
#                 end
#                 for i2 in 1:length(A[2])
#                     if board[A[2][i2]] < -1 && board[A[1][i2]] > 0
#                         push!(valid, (A[2][i2], i, A[1][i2]))
#                         hop = true
#                     end
#                 end
#                 if !hop
#                     for i3 in 1:length(A[3])
#                         if board[A[3][i3]] < 0
#                             push!(valid, (A[3][i3], i))
#                         end
#                     end
#                     for i1 in 1:length(A[1])
#                         if board[A[1][i1]] < -1
#                             push!(valid, (A[1][i1], i))
#                         end
#                     end
#                 end # not hop
#             end # if board[i] == 0
#         end # for i
#     else # if
#         hop = false
#         for i in 1:length(board)
#             if board[i] == 0
#                 # D_HD_U_HU
#                 A = actions[i]
#                 for i2 in 1:length(A[2])
#                     if board[A[2][i2]] > 0 && board[A[1][i2]] < 0
#                         push!(valid, (A[2][i2], i, A[1][i2]))
#                         hop = true
#                     end
#                 end
#                 for i4 in 1:length(A[4])
#                     if board[A[4][i4]] > 1 && board[A[3][i4]] < 0
#                         push!(valid, (A[4][i4], i, A[3][i4]))
#                         hop = true
#                     end
#                 end
#                 if !hop
#                     for i1 in 1:length(A[1])
#                         if board[A[1][i1]] > 0
#                             push!(valid, (A[1][i1], i))
#                         end
#                     end
#                     for i3 in 1:length(A[3])
#                         if board[A[3][i3]] > 1
#                             push!(valid, (A[3][i3], i))
#                         end
#                     end
#                 end # not hop
#             end # if board[i] == 0
#         end # for i
#     end # if player
#     trimIfAttack(valid)
#     if length(valid) == 0
#         g.winner = g.pID == 0 ? -1 : 1
#     end
#     return valid
# end
#
# function getValidMovesAfterHop(g::Game, pos)
#     player = g.pID
#     valid = Array{Tuple{Int64,Int64,Vararg{Int64,N} where N},1}()
#     board = g.states
#     # D_HD_U_HU
#     A = actions[pos]
#     if player == 1
#         for i2 in 1:length(A[2])
#             if board[A[2][i2]] == 0 && board[A[1][i2]] > 0
#                 push!(valid, (pos, A[2][i2], A[1][i2]))
#             end
#         end
#         if board[pos] < -1
#             for i4 in 1:length(A[4])
#                 if board[A[4][i4]] == 0 && board[A[3][i4]] > 0
#                     push!(valid, (pos, A[4][i4], A[3][i4]))
#                 end
#             end
#         end
#     else # player > 0
#         for i4 in 1:length(A[4])
#             if board[A[4][i4]] == 0 && board[A[3][i4]] < 0
#                 push!(valid, (pos, A[4][i4], A[3][i4]))
#             end
#         end
#         if board[pos] > 1
#             for i2 in 1:length(A[2])
#                 if board[A[2][i2]] == 0 && board[A[1][i2]] < 0
#                     push!(valid, (pos, A[2][i2], A[1][i2]))
#                 end
#             end
#         end
#     end
#     if length(valid) == 0
#         g.hopMove = false
#         g.pID = div((sign(board[pos]) + 1), 2)
#     end
#     return valid
# end

function play()
    s = ""
    while s != "q"
        s = readline(STDIN)
        x, y = Int(s[1]) - 96, s[2:end]
        y = parse(Int64, y)
        res = 8div(y - 1, 2) + x

        println("Playing $s ($res)")
    end
end

function sh(game::Game)
    function p(c::Int64)
        if c == 1
            return "●"
        elseif c == -1
            return "□"
        elseif c == 2
            return "◆"
        elseif c == -2
            return "◇"
        elseif c == 9
            return "*"
        else
            return " "
        end
    end
    a = copy(game.states)
    last = game.lastAction
    if last[1] != 0
        a[last[1]] = 9
    end
    a = a.'
    println("      1   2   3   4   5   6   7   8")
    println("    ╔═══╤═══╤═══╤═══╤═══╤═══╤═══╤═══╗")
    print("  A ║   │ $(p(a[1])) │   │ ")
    println("$(p(a[2])) │   │ $(p(a[3])) │   │ $(p(a[4])) ║")
    println("    ╟───┼───┼───┼───┼───┼───┼───┼───╢")

    print("  B ║ $(p(a[5])) │   │ $(p(a[6])) │   ")
    println("│ $(p(a[7])) │   │ $(p(a[8])) │   ║")
    println("    ╟───┼───┼───┼───┼───┼───┼───┼───╢")

    print("  C ║   │ $(p(a[9])) │   │ ")
    println("$(p(a[10])) │   │ $(p(a[11])) │   │ $(p(a[12])) ║")
    println("    ╟───┼───┼───┼───┼───┼───┼───┼───╢")

    println("  D ║ $(p(a[13])) │   │ $(p(a[14])) │   │ $(p(a[15])) │   │ $(p(a[16])) │   ║")
    println("    ╟───┼───┼───┼───┼───┼───┼───┼───╢")
    println("  E ║   │ $(p(a[17])) │   │ $(p(a[18])) │   │ $(p(a[19])) │   │ $(p(a[20])) ║")
    println("    ╟───┼───┼───┼───┼───┼───┼───┼───╢")

    print("  F ║ $(p(a[21])) │   │ $(p(a[22])) │   ")
    println("│ $(p(a[23])) │   │ $(p(a[24])) │   ║")
    println("    ╟───┼───┼───┼───┼───┼───┼───┼───╢")

    print("  G ║   │ $(p(a[25])) │   │ $(p(a[26])) │ ")
    println("  │ $(p(a[27])) │   │ $(p(a[28])) ║")
    println("    ╟───┼───┼───┼───┼───┼───┼───┼───╢")

    print("  H ║ $(p(a[29])) │   │ $(p(a[30])) │ ")
    println("  │ $(p(a[31])) │   │ $(p(a[32])) │   ║")
    println("    ╚═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╝")
end
