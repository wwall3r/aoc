package main

import "core:log"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:slice"
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

    log.debugf("part: %d file: %s", part, file)

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

part1 :: proc(input: ^string) {
    start := time.now()

    max_calories := 0
    calories := 0

    for line in strings.split_lines_iterator(input) {
        food, ok := strconv.parse_int(line)
        if ok {
            calories += food
        } else {
            max_calories = max(max_calories, calories)
            calories = 0
        }
    }

    max_calories = max(max_calories, calories)

    runtime := time.since(start)
    log.info(max_calories)
    log.info("Solved in", runtime)
}

part2 :: proc(input: ^string) {
    start := time.now()

    elves: [dynamic]int
    max_calories := 0
    calories := 0

    for line in strings.split_lines_iterator(input) {
        food, ok := strconv.parse_int(line)
        if ok {
            calories += food
        } else {
            append(&elves, calories)
            calories = 0
        }
    }

    append(&elves, calories)

    slice.reverse_sort(elves[:])

    sum := 0
    for s in 0..=2 {
        sum += elves[s]
    }

    runtime := time.since(start)
    log.info(sum)
    log.info("Solved in", runtime)
}

