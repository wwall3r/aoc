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
    // parse
    runtime := time.since(start)
    log.info("Parsed in", runtime)

    start = time.now()
    // solve
    runtime = time.since(start)
    log.info("Solved in", runtime)
}

part2 :: proc(input: ^string) {
    start := time.now()
    // parse
    runtime := time.since(start)
    log.info("Parsed in", runtime)

    start = time.now()
    // solve
    runtime = time.since(start)
    log.info("Solved in", runtime)

}

