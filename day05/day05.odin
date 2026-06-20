package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:time"

Error :: enum u8 {
    ArgsError = 1,
    FileNotFoundError = 2,
    PartArgError = 3,
    ParseError = 4,
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

    if err != nil {
        exit_messages := [Error]string {
            .ArgsError         = "must provide part and input, e.g.: odin run . -- 1 input",
            .PartArgError      = "Part should be either 1, 2, or 0 for both",
            .FileNotFoundError = "Failed to load file",
            .ParseError        = "Failed to parse input",
        }
        log.errorf("%v: %s", err, exit_messages[err])
    }
}

run :: proc() -> (err: Error) {
    if len(os.args) < 3 do return .ArgsError

    part := strconv.parse_int(os.args[1], 10) or_else -1
    if part < 0 || part > 2 do return .PartArgError

    file := os.args[2]
    log.debug("part:", part, "file:", file)

    data, read_err := os.read_entire_file(file, context.allocator)
    if read_err != nil do return .FileNotFoundError
    defer delete(data)

    input := string(data)

    if part == 0 || part == 1 do solve(input, false) or_return
    if part == 0 || part == 2 do solve(input, true) or_return

    return nil
}

parse_int :: proc(s: string) -> (n: int, err: Error) {
    parsed, ok := strconv.parse_int(s, 10)
    if !ok do return 0, .ParseError
    return parsed, nil
}

solve :: proc(input: string, simultaneous: bool) -> (err: Error) {
    start := time.now()
    stacks, moves := parse(input) or_return
    defer {
        for stack in stacks do delete(stack)
        delete(stacks)
    }
    log.info("Parsed in", time.since(start))

    start = time.now()
    for move_str in strings.split_lines_iterator(&moves) {
        move_parts := strings.split(move_str, " ", context.temp_allocator)
        if len(move_parts) < 6 do continue

        num := parse_int(move_parts[1]) or_return
        src := parse_int(move_parts[3]) or_return
        dst := parse_int(move_parts[5]) or_return

        if simultaneous {
            move_many(&stacks, num, src - 1, dst - 1)
        } else {
            for _ in 0 ..< num do move_one(&stacks, src - 1, dst - 1)
        }
    }
    free_all(context.temp_allocator)

    top_items := strings.builder_make()
    defer strings.builder_destroy(&top_items)
    for stack in stacks do strings.write_byte(&top_items, stack[len(stack) - 1])
    log.info(strings.to_string(top_items))

    log.info("Solved in", time.since(start))
    return nil
}

parse :: proc(input: string) -> (stacks: [dynamic][dynamic]u8, moves: string, err: Error) {
    parts := strings.split(input, "\n\n", context.temp_allocator)
    if len(parts) < 2 do return nil, "", .ParseError

    positions := strings.split(parts[0], "\n", context.temp_allocator)
    p := len(positions) - 1

    // Bottom-most row holds the stack labels; each non-space column is a stack.
    // ASCII-only input, so byte indexing is safe.
    for c, i in positions[p] {
        if c == ' ' do continue

        stack := [dynamic]u8{}
        for j := p - 1; j >= 0; j -= 1 {
            row := positions[j]
            if i < len(row) && row[i] != ' ' {
                append(&stack, row[i])
            }
        }
        append(&stacks, stack)
    }

    return stacks, parts[1], nil
}

move_one :: proc(stacks: ^[dynamic][dynamic]u8, src, dst: int) {
    append(&stacks[dst], pop(&stacks[src]))
}

move_many :: proc(stacks: ^[dynamic][dynamic]u8, num, src, dst: int) {
    n := min(num, len(stacks[src]))
    new_len := len(stacks[src]) - n
    append(&stacks[dst], ..stacks[src][new_len:])
    resize(&stacks[src], new_len)
}
