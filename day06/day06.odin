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

    messages := [Error]string{
        .ArgsError = "must provide part and input, e.g.: odin run . -- 1 input",
        .PartArgError = "Part should be either 1, 2, or 0 for both",
        .FileNotFoundError = "Failed to load file",
    }

    if err != nil {
        log.errorf("%v: %s", err, messages[err])
    }
}


run :: proc() -> (err: Error) {
    if len(os.args) < 3 {
        return .ArgsError
    }

    part, ok := strconv.parse_int(os.args[1], 10)
    if !ok || part < 0 || part > 2 {
        return .PartArgError
    }

    file := os.args[2]

    log.debug("part:", part, "file:", file)

    data, read_err := os.read_entire_file(file, context.allocator)
    if read_err != nil {
        return .FileNotFoundError
    }
    defer delete(data)

    input := string(data)

    if part == 0 || part == 1 {
        part1(input)
    }

    if part == 0 || part == 2 {
        part2(input)
    }

    return nil
}


part1 :: proc(input: string) {
    solve(input, 4)
}

part2 :: proc(input: string) {
    solve(input, 14)
}

solve :: proc(input: string, num_unique: int) {
    start := time.now()
    signals := strings.split(input, "\n", context.temp_allocator)

    for signal in signals {
        for i in 3..<len(signal) {
            when ODIN_DEBUG {
                fmt.println("character", i)
            }

            if is_marker(signal, num_unique, i) {
                log.info(i + 1)
                break
            }
        }
    }

    free_all(context.temp_allocator)
    runtime := time.since(start)
    log.info("Solved in", runtime)
}


is_marker :: proc(signal: string, num_unique, i: int) -> bool {
    if i < num_unique - 1 || i >= len(signal) {
        when ODIN_DEBUG {
            fmt.println("is_marker not long enough return")
        }
        return false
    }

    bitset: u32 = 0

    when ODIN_DEBUG {
        fmt.println("checking:", signal[i - (num_unique - 1) : i + 1])
    }

    for j in (i - (num_unique - 1))..=i {
        b := signal[j]
        assert(type_of(b) == u8, "iteration is not bytes!")
        when ODIN_DEBUG {
            fmt.println("b", b, b - 'a')
        }
        bit : u32 = 1 << (b - 'a')

        if bitset & bit > 0 {
            when ODIN_DEBUG {
                fmt.println("is_marker found repeated return", bitset, bit)
            }
            return false
        }

        bitset = bitset | bit
    }

    return true
}
