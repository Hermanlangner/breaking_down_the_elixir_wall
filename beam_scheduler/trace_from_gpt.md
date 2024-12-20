https://www.erlang.org/doc/apps/kernel/trace
# Erlang Tracing Flags Overview

The `trace_info_flag()` type in Erlang defines a set of flags that determine which events and information are included in trace messages. Applying these flags via tracing functions (e.g., `erlang:trace/3`) lets you monitor and debug various aspects of your system at runtime without altering source code.

---

## Event-Related Flags

### `call`
- **Description:** Emits a trace message whenever a traced process calls a function.
- **Use Case:** Debugging which functions a process invokes, profiling code execution, and identifying performance hotspots.

### `return_to`
- **Description:** Emits a trace message when a traced function returns to another function.
- **Use Case:** Understanding control flow, paired with `call` for detailed function entry/exit logging.

### `exiting`
- **Description:** Emits a trace message when a process exits.
- **Use Case:** Monitoring process lifecycle, diagnosing unexpected process terminations.

### `send`
- **Description:** Emits a trace message whenever a traced process sends a message.
- **Use Case:** Debugging communication patterns, message-based race conditions, and load caused by message passing.

### `receive`
- **Description:** Emits a trace message when a traced process receives a message.
- **Use Case:** Understanding message flow between processes and diagnosing concurrency issues when combined with `send`.

### `running`
- **Description:** Emits a trace message whenever a traced entity (process or port) starts running on a scheduler.
- **Use Case:** Analyzing scheduler behavior and CPU scheduling latency.

### `running_procs`
- **Description:** Emits a trace message specifically when a process starts running.
- **Use Case:** Focused view on when processes get CPU time, useful for debugging scheduling delays.

### `running_ports`
- **Description:** Emits a trace message specifically when a port starts running.
- **Use Case:** Monitoring port activity and I/O scheduling.

---

## Process/Port Coverage Flags

### `procs`
- **Description:** Enables tracing of process-related events. Must be combined with event flags like `call` or `send` to produce output.
- **Use Case:** Master switch for process tracing; turn on to trace calls, sends, receives, etc.

### `ports`
- **Description:** Enables tracing of port-related events. Must be combined with event flags to produce output.
- **Use Case:** Debugging external I/O operations or system interactions via ports.

---

## Spawn/Link-Related Flags

These flags propagate tracing to new or linked processes/ports.

### `set_on_spawn`
- **Description:** Newly spawned processes from a traced process inherit the same trace flags.
- **Use Case:** Ensuring that child processes are also traced, allowing end-to-end tracing of spawned processes.

### `set_on_first_spawn`
- **Description:** Like `set_on_spawn` but only applies to the first spawned process.
- **Use Case:** Rare scenarios where you only want to propagate tracing once.

### `set_on_link`
- **Description:** When a traced process links to another process, the linked process also becomes traced.
- **Use Case:** Tracing related process groups via links, aiding in debugging of supervised processes.

### `set_on_first_link`
- **Description:** Like `set_on_link` but only applies to the first link created.
- **Use Case:** Controlling trace propagation in a very targeted way.

---

## Additional Information Flags

### `arity`
- **Description:** When combined with `call`, includes function arity in trace messages.
- **Use Case:** More detailed function call info, useful for overloaded or similarly named functions.

### `garbage_collection`
- **Description:** Emits trace messages related to garbage collection events.
- **Use Case:** Memory profiling, understanding GC pauses, and optimizing memory usage.

---

## Timestamp Flags

### `timestamp`
- **Description:** Includes a timestamp (based on Erlang VM time) in each trace message.
- **Use Case:** Measuring intervals between events, correlating with logs and metrics.

### `monotonic_timestamp`
- **Description:** Uses a monotonic clock for timestamps, unaffected by system time changes.
- **Use Case:** Accurately measuring elapsed times for profiling, ignoring system clock adjustments.

### `strict_monotonic_timestamp`
- **Description:** A stricter form of `monotonic_timestamp` guaranteeing strictly increasing timestamps.
- **Use Case:** Precise performance measurements where event ordering and timing must be unambiguous.

---

## Miscellaneous

### `silent`
- **Description:** Suppresses some default formatting in trace output.
- **Use Case:** Collecting trace data programmatically without noise, or integrating with external analysis tools.

---

# Summary of Use Cases

- **Performance Profiling:** Use `call`, `arity`, `return_to`, `garbage_collection`, and timestamps to analyze code execution and timing.
- **Concurrency Debugging:** Use `procs`, `ports`, `send`, `receive`, `running_procs`, `running_ports` to understand process scheduling and message flow.
- **Lifecycle Monitoring:** Use `exiting` and spawn/link flags (`set_on_spawn`, `set_on_link`) to track process lifecycle and related processes.
- **Accurate Timing:** Use `monotonic_timestamp` or `strict_monotonic_timestamp` for precise and stable event timing.
