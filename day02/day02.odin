package main

import "core:log"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:time"

Error :: enum {
    ArgsError,
    FileNotFoundError,
    PartArgError,
}

main :: proc() {
    logger := log.create_console_logger()
    context.logger = logger

    err := run()

    exit_code := 0 if err == nil else int(err) + 1
    exit_message: string = ""

    switch err {
    case nil:
    case .ArgsError:
        exit_message = "must provide part and input, e.g.: odin run . -- 1 input"
    case .PartArgError:
        exit_message = "Part should be either 1, 2, or 0 for both"
    case .FileNotFoundError:
        exit_message = "Failed to load file"
    }

    if exit_message != "" {
        log.errorf("%v: %s", err, exit_message)
    }

    log.destroy_console_logger(logger)
    os.exit(exit_code)
}

run :: proc() -> (err: Error) {
    if len(os.args) < 3 {
        return Error.ArgsError
    }

    part, ok := strconv.parse_int(os.args[1], 10)
    if !ok || part < 0 || part > 2 {
        return Error.PartArgError
    }

    file := os.args[2]

    log.debug("part:", part, "file:", file)

    data, read_err := os.read_entire_file(file, context.allocator)
    if read_err != nil {
        return Error.FileNotFoundError
    }
    defer delete(data)

    input := string(data)

    if part == 0 || part == 1 {
        part1(&input)
    }

    input = string(data)

    if part == 0 || part == 2 {
        part2(&input)
    }

    return nil
}

Plays :: enum {
    Rock,
    Paper,
    Scissors,
}

part1 :: proc(input: ^string) {
    start := time.now()

    score := 0

    opponent: Plays
    player: Plays

    for line in strings.split_lines_iterator(input) {
        opponent = nil
        player = nil

        parts := strings.split(line, " ")

        // possibly overly clever: enum defaults to an int: 0, 1, 2
        // so just diff the char in the input string with the offset
        // for that player's input codes
        opponent = Plays(parts[0][0] - 'A')
        player = Plays(parts[1][0] - 'X')

        score += int(player) + 1

        if opponent == player {
            score += 3
        } else if int(player) == (int(opponent) + 1) %% 3 {
            score += 6
        }
    }

    log.info(score)
    runtime := time.since(start)
    log.info("Solved in", runtime)
}

Results :: enum {
    Lose,
    Draw,
    Win,
}

part2 :: proc(input: ^string) {
    start := time.now()

    score := 0

    opponent: Plays
    result: Results
    player: Plays

    for line in strings.split_lines_iterator(input) {
        opponent = nil
        result = nil
        player = nil

        parts := strings.split(line, " ")

        // possibly overly clever: enum defaults to an int: 0, 1, 2
        // so just diff the char in the input string with the offset
        // for that player's input codes
        opponent = Plays(parts[0][0] - 'A')
        result = Results(parts[1][0] - 'X')

        switch result {
        case .Lose:
            player = Plays((int(opponent) - 1) %% 3)
        case .Draw:
            score += 3
            player = opponent
        case .Win:
            score += 6
            player = Plays((int(opponent) + 1) %% 3)
        }

        score += int(player) + 1
    }

    log.info(score)
    runtime := time.since(start)
    log.info("Solved in", runtime)
}
