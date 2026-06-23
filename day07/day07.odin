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

    input := strings.trim_space(string(data))

    if part == 0 || part == 1 || part == 2 {
        solve(input)
    }

    return nil
}

solve :: proc(input: string) {
    start := time.now()

    path := make([dynamic]string, context.temp_allocator)
    size_map := make(map[string]int, context.temp_allocator)

    for line in strings.split(input, "\n", context.temp_allocator) {
        parts := strings.fields(line, context.temp_allocator)
        assert(len(parts) >= 2, "Incorrect line parse")

        if strings.compare(parts[0], "$") == 0 {
            if strings.compare(parts[1], "cd") == 0 {
                assert(len(parts) == 3, "Line was parsed as '$ cd x'")

                if strings.compare(parts[2], "..") == 0 {
                    pop(&path)
                } else {
                    append(&path, parts[2])
                }
            }
        } else if strings.compare(parts[0], "dir") != 0 {
            // file
            size, size_parse_ok := strconv.parse_int(parts[0], 10)
            assert(size_parse_ok, "Could not parse file size as int!")

            path_str := ""

            for p in path {
                path_str = strings.concatenate({path_str, p, "/"}, context.temp_allocator)

                if path_str in size_map {
                    size_map[path_str] += size
                } else {
                    size_map[path_str] = size
                }
            }
        }
    }

    // part 1
    sum := 0

    // part 2
    target_size := 30_000_000
    current_size := size_map["//"]
    unused := 70_000_000 - current_size
    to_free := target_size - unused
    min_dir_size := max(int)

    for path, value in size_map {
        // part 1
        if value <= 100_000 {
            sum += value
        }

        // part 2
        if (value >= to_free) {
            min_dir_size = min(value, min_dir_size)
        }
    }

    log.info("Part 1:", sum)
    log.info("Part 2:", min_dir_size)
    runtime := time.since(start)
    log.info("Solved in", runtime)

    free_all(context.temp_allocator)
}

