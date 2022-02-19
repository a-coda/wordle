# Run from REPL via:
#   include("wordle.jl")
#   solve("abbey", "wordlistfile.txt")

@enum Score grey yellow green 

const WORD_SIZE = 5
const ALL_GREEN = fill(green, WORD_SIZE)
const ALL_GREY  = fill(grey, WORD_SIZE)

# Finds the answer from the dictionary by guessing a word, getting the
# score, then filtering out words that can't match based on the latest
# score, then tries again.
function solve(answer, filename)
    attempts, remaining_words = 1, load_words(filename)
    while true
        guess = guess_word(remaining_words)
        score = score_word(guess, answer)
        if is_finished(score)
            println(guess, " ", graphic_score(score), " in ", attempts, " attempts")
            return 
        end
        remaining_words = filter(word -> still_possible(guess, score, word), remaining_words)
        println(guess, " ", graphic_score(score), " with ", length(remaining_words), " remaining words")
        if length(remaining_words) == 0
            return # word not in dictionary?
        end
        attempts += 1
    end
end
        
# Load a newline delimited list of 5-character words
function load_words(filename)
    readlines(filename)
end

# Make a guess at the word based on the a word that uses the most
# frequenct characters of the remaining words.
function guess_word(words)
    frequencies = collect_character_frequencies(words)
    average_word = find_average_word(frequencies)
    find_nearest_real_word(average_word, words)
end

# Collects the frequencies of the characters in each position
function collect_character_frequencies(words)
    frequencies = [Dict() for d in 1:WORD_SIZE]
    for word in words
        for i in 1:WORD_SIZE
            count = get(frequencies[i], word[i], 0)
            frequencies[i][word[i]] = count + 1
        end
    end
    frequencies
end    

# Assembles an imaginary word based on the most frequent characters in
# each position.
function find_average_word(frequencies)
    average_word = fill(' ', WORD_SIZE)
    for i in 1:WORD_SIZE
        freq_character, freq_count = nothing, nothing
        for (character, count) in frequencies[i]
            if isnothing(freq_character) || count > freq_count
                freq_character, freq_count = character, count
            end
        end
        average_word[i] = freq_character
    end
    join(average_word)
end    

# Finds nearest real word to average word (representing frequent
# characters) by valuing the matches against the average word.
function find_nearest_real_word(average_word, words)
    best_word, best_value = nothing, nothing
    for word in words
        value = value_of_score(score_word(word, average_word))
        if isnothing(best_word) || value > best_value
            best_word, best_value = word, value
        end
    end
    best_word
end

# Determines the value of the score by assigning values to exact
# and inexact matches
function value_of_score(score)
    values = Dict(green => 1.0, yellow => 0.5, grey => 0.0)
    sum(s -> values[s], score)
end

# Scores a word by connecting the characters with the other word
# and then translating that into a score
function score_word(word, answer)
    score_match(connect_words(word, answer))
end

# Translates a matching between one word and another into a score
function score_match(match)
    score = copy(ALL_GREY)
    for i in 1:WORD_SIZE
        if match[i] == i
            score[i] = green
        elseif match[i] > 0
            score[i] = yellow
        else
            score[i] = grey
        end
    end
    score
end    

# Connects exact matches first and then inexact matches.  
function connect_words(word, answer)
    match = fill(0, 5) 
    connect_exact_matches(word, answer, match)
    for i in 1:WORD_SIZE
        if match[i] == 0
            connect_inexact_matches(word, i, answer, match)
        end
    end
    match
end

# Connects exact matches between the words
function connect_exact_matches(word, answer, match)
    for i in 1:WORD_SIZE
        if word[i] == answer[i]
            match[i] = i
        end 
    end
end

# Connects inexact matches between different positions in the words
function connect_inexact_matches(guess, i, answer, match)
    for j in 1:WORD_SIZE
        if i != j && !(j in match) && guess[i] == answer[j]
            match[i] = j
            return 
        end
    end
end

function still_possible(guess, score, candidate)
    score_word(guess, candidate) == score
end

# Have we exactly matched every character of the word?
function is_finished(score)
    score == ALL_GREEN
end

# Translate score into some unicode blocks
function graphic_score(score)
    graphics = Dict(green => '\u25A0', yellow => '\u25AA', grey => '\u25A1')
    join([graphics[s] for s in score])
end

# 'unit tests'

@assert score_word("sound", "could") == [grey, green, green, grey, green]
@assert score_word("occur", "could") == [yellow, yellow, grey, yellow, grey]

@assert connect_words("count", "could") == [1, 2, 3, 0, 0]
@assert connect_words("mount", "could") == [0, 2, 3, 0, 0]
@assert connect_words("coult", "could") == [1, 2, 3, 4, 0]

@assert connect_words("topic", "could") == [0, 2, 0, 0, 1]
@assert connect_words("xxxxx", "could") == [0, 0, 0, 0, 0]
@assert connect_words("duloc", "could") == [5, 3, 4, 2, 1]

@assert still_possible("occur", score_word("occur", "could"), "bound") == false
@assert still_possible("occur", score_word("occur", "could"), "count") == true
@assert still_possible("occur", score_word("occur", "could"), "occam") == false
@assert still_possible("occur", score_word("occur", "could"), "could") == true
@assert still_possible("occur", score_word("occur", "could"), "count") == true
@assert still_possible("could", score_word("occur", "could"), "could") == false
@assert still_possible("count", score_word("occur", "could"), "could") == false
@assert still_possible("apiin", score_word("apiin", "aalii"), "aalii") == true
@assert still_possible("cocco", score_word("cocco", "could"), "could") == true
@assert still_possible("seave", score_word("seave", "ultra"), "alara") == false

@assert collect_character_frequencies(["tiger", "spoor", "sheer"]) ==  [ Dict('s' => 2, 't' => 1), Dict('h' => 1, 'i' => 1, 'p' => 1), Dict('g' => 1, 'e' => 1, 'o' => 1), Dict('e' => 2, 'o' => 1), Dict('r' => 3) ]
@assert find_average_word(collect_character_frequencies(["tiger", "spoor", "sheer"])) == "shger"
@assert find_nearest_real_word("shger", ["tiger", "spoor", "sheer"]) == "sheer"

# COMMENTS
# obligatory wordle solver
# origin of dictionary
# test instead of assignment bug
# late runtime notification of undefined functions (REPL?)
# late runtime notification of nothing
# costly search, bad algorithm
# non-functional feeling in some functions
# unit tests as asserts
# assumed score problems
# switched to character frequency
# not using same dictionary
# used REPL
# does it the hard way (keeping hints)
# fast
# FORTRANY (okay for Julia!)
# NYT change
# character frequencies? (later change?)
# colons
# badly use template function with lambdas
# most like Dylan
# opening book like chess
# had to delete a big duplicate mess of parallel functions
# repl remembers old functions

# TODO
# findmax
