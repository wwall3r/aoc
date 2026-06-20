package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:time"
import "core:unicode/utf8"

Error :: enum u8 {
    ArgsError = 1,
    FileNotFoundError = 2,
    PartArgError = 3,
}

main :: proc() {
    exit_code := 0
    defer os.exit(exit_code)

    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                fmt.eprintfln("=== %v allocations not freed: ===", len(track.allocation_map))
                for _, entry in track.allocation_map {
                    fmt.eprintfln("- %v bytes @ %v", entry.size, entry.location)
                }
            }

            mem.tracking_allocator_destroy(&track)
        }
    }

    logger := log.create_console_logger()
    defer log.destroy_console_logger(logger)
    context.logger = logger

    err := run()

    exit_code = 0 if err == nil else int(err)
    exit_message: string = ""

    switch err {
    case .ArgsError:
        exit_message = "must provide part and input, e.g.: odin run . -- 1 input"
    case .PartArgError:
        exit_message = "Part should be either 1, 2, or 0 for both"
    case .FileNotFoundError:
        exit_message = "Failed to load file"
    }

    if err != nil {
        log.errorf("%v: %s", err, exit_message)
    }
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

part1 :: proc(input: ^string) {
    start := time.now()
    stacks, moves := parse(input)
    defer {
        for stack in stacks do delete(stack)
        delete(stacks)
    }

    runtime := time.since(start)
    log.info("Parsed in", runtime)

    start = time.now()


    for move_str in strings.split_lines_iterator(&moves) {
        move_parts := strings.split(move_str, " ")
        defer delete(move_parts)

        num_to_move, _ := strconv.parse_int(move_parts[1], 10)
        source, _ := strconv.parse_int(move_parts[3], 10)
        dest, _ := strconv.parse_int(move_parts[5], 10)

        for i in 0..<num_to_move {
            move(&stacks, source - 1, dest -1)
        }
    }

    top_items := strings.builder_make()
    defer strings.builder_destroy(&top_items)

    for stack in stacks {
        strings.write_rune(&top_items, stack[len(stack) - 1])
    }

    log.info(strings.to_string(top_items))

    runtime = time.since(start)
    log.info("Solved in", runtime)
}

parse :: proc(input: ^string) -> ([dynamic][dynamic]rune, string) {
    parts := strings.split(input^, "\n\n")
    defer delete(parts)

    positions := strings.split(parts[0], "\n")
    defer delete(positions)

    p := len(positions) - 1

    stacks := [dynamic][dynamic]rune{}

    for r, i in positions[p] {
        // technically this won't handle multi-rune positions, but our input 
        // only contains 9 so whatever
        if !strings.is_space(r) {
            stack := [dynamic]rune{}

            for j := p - 1; j >= 0; j -= 1 {
                runes := utf8.string_to_runes(positions[j])
                defer delete(runes)

                if !strings.is_space(runes[i]) {
                    append(&stack, runes[i])
                }
            }

            append(&stacks, stack)
        }
    }

    fmt.println("stacks:")
    for stack in stacks {
        fmt.println(stack)
    }

    return stacks, parts[1]
}

move :: proc(stacks : ^[dynamic][dynamic]rune, source, dest: int) {
    item := pop(&stacks[source])
    append(&stacks[dest], item)
}

part2 :: proc(input: ^string) {
    start := time.now()
    stacks, moves := parse(input)
    defer {
        for stack in stacks do delete(stack)
        delete(stacks)
    }
    runtime := time.since(start)
    log.info("Parsed in", runtime)

    start = time.now()
    for move_str in strings.split_lines_iterator(&moves) {
        move_parts := strings.split(move_str, " ")
        defer delete(move_parts)

        num_to_move, _ := strconv.parse_int(move_parts[1], 10)
        source, _ := strconv.parse_int(move_parts[3], 10)
        dest, _ := strconv.parse_int(move_parts[5], 10)

        move2(&stacks, num_to_move, source - 1, dest -1)
    }

    top_items := strings.builder_make()
    defer strings.builder_destroy(&top_items)

    for stack in stacks {
        strings.write_rune(&top_items, stack[len(stack) - 1])
    }

    log.info(strings.to_string(top_items))

    runtime = time.since(start)
    log.info("Solved in", runtime)
}

move2 :: proc(stacks : ^[dynamic][dynamic]rune, num, source, dest : int) {
    source_len := len(stacks[source])
    num := min(num, source_len)
    new_len := source_len - num
    append(&stacks[dest], ..stacks[source][new_len:])
    resize(&stacks[source], new_len)
}
