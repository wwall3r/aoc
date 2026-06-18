package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:time"

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

    seen := make(map[rune]bool)
    defer delete(seen)

    sum := 0
    for line in strings.split_lines_iterator(input) {
        l := len(line)
        left := line[0 : l / 2] 
        right := line[l / 2 : l]

        clear_map(&seen)

        for r in left {
            seen[r] = true
        }

        for r in right {
            if seen[r] {
                sum += priority(r)
                break
            }
        }
    }

    log.info(sum)
    runtime := time.since(start)
    log.info("Solved in", runtime)
}

part2 :: proc(input: ^string) {
    start := time.now()

    line_set := make(map[rune]bool)
    defer delete(line_set)

    seen := make(map[rune]u8)
    defer delete(seen)

    sum := 0
    elf := 0

    for line in strings.split_lines_iterator(input) {
        clear_map(&line_set)

        for r in line {
            line_set[r] = true
        }

        for r in line_set {
            if r in seen {
                seen[r] += 1
            } else {
                seen[r] = 1
            }
        }

        if elf == 2 {
            for key, value in seen {
                if value == 3 {
                    sum += priority(key)
                    clear_map(&seen)
                    break
                }
            }

            elf = 0
        } else {
            elf += 1
        }
    }

    log.info(sum)
    runtime := time.since(start)
    log.info("Solved in", runtime)
}

priority :: proc(r: rune) -> int {
    // convert rune to char/int
    bytes := transmute([4]u8)(r)
    ch := int(bytes[0])

    lowerDiff := ch - 'a'

    if lowerDiff >= 0 {
        return lowerDiff + 1
    }

    return ch - 'A' + 27
}
