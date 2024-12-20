# session_create(Name, Tracer, Opts)

The `session_create/3` function is used to create a new, isolated trace session in the Erlang runtime. Each trace session can have its own tracer entity and configuration, allowing for multiple, independent tracing setups without interference.

## Parameters

- **Name**:
  An atom that names the session. This is primarily for identification and ease of reference, especially when inspecting or interacting with multiple sessions. For example, `:my_session` could be a suitable name.

- **Tracer**:
  The tracer determines where trace events are sent or how they are handled. It can be:
  - A PID representing a process that will receive trace messages as Erlang messages.
  - A port, similarly receiving trace messages.
  - A tuple `{Module, State}`, representing a tracer module that will handle trace events through its callbacks. This approach allows more sophisticated manipulation or filtering of trace events before final output.

- **Opts**:
  Currently, this list must be empty (`[]`). No additional options are supported at this time.

## Behavior

When you call `session_create/3` with a given Name and Tracer, it returns an opaque session handle. This handle keeps the session active. As long as the handle is accessible (not garbage collected), the session remains alive. Multiple sessions can exist at once, each with its own tracer and configuration.

Once created, the session is isolated from others. You can enable tracing for specific processes, ports, functions, or message patterns within this session without affecting other sessions or the default tracing mechanisms.

## Possible Responses

- On success, `session_create/3` returns a session handle. This handle is a reference that you will use when applying further trace settings (e.g., enabling `:call` flags on processes or functions) and eventually destroying the session with `session_destroy/1`.
- If arguments are invalid or unsupported, the function may raise an error. For example, supplying invalid types for `Name` or `Tracer` could result in a `badarg` error.

## Use Cases

- **Focused debugging**: Create a session named `:debug_session` and specify a particular process as the Tracer. Then enable tracing on a subset of your system to debug issues without producing trace output for unrelated components.
- **Profiling a subset of functions**: By creating a session for profiling, you can send trace messages to a custom tracer module that collects and summarizes performance data, leaving the rest of the node’s processes unaffected.
- **Coexisting Tools**: With multiple sessions, two separate teams or tools can trace different parts of the system simultaneously. For example, one session for debugging a new feature, another for monitoring performance metrics, each with its own Tracer, avoiding conflicts between them.


# session_destroy(Session)

The `session_destroy/1` function is used to end a trace session and clean up all associated trace settings that were applied to processes, ports, and functions.

## Parameters

- **Session**:
  The session handle returned by `session_create/3`. This handle identifies which trace session you want to destroy.

## Behavior

When you call `session_destroy(Session)`, it terminates the specified trace session. All tracing configurations, such as trace flags and match specifications applied to processes, ports, and functions under this session, are removed.

If you had multiple sessions running, destroying one session does not affect the others. Once the session is destroyed, no more trace messages for that session will be produced.

## Possible Responses

- On success, returns `true` if the session was active and is now destroyed.
- Returns `false` if the session had already been destroyed or had been garbage collected.

## Use Cases

- **Ending a Debugging Session**: After you have gathered enough trace data from a particular session dedicated to debugging, you can clean up and return the system to normal by destroying that session.
- **Resource Management**: Destroying sessions promptly after use ensures that processes and ports are not unnecessarily traced, which can reduce overhead and clutter in your runtime environment.

# delivered(Session, Tracee)

The `delivered/2` function integrates with a given session to ensure trace messages have been delivered up to a certain point.

## Parameters

- **Session**:
  The session handle returned by `session_create/3`.

- **Tracee**:
  A PID representing a traced process, or the atom `all`.
  - If a specific PID is given, the function focuses on trace messages related to that process.
  - If `all` is given, it relates to all traced entities under the session.

## Behavior

`delivered(Session, Tracee)` returns a reference. This reference can be used to determine when all previously sent trace messages related to `Tracee` within `Session` have been delivered to the Tracer. By monitoring when the tracer receives a `trace_delivered` message with this reference, you can synchronize and confirm that all prior trace events have been fully processed.

## Possible Responses

- Returns a reference on success.
- Errors if invalid arguments are provided.

## Use Cases

- **Synchronization Point**: If your tracer logic requires knowledge that all currently queued trace messages have been handled, you can use `delivered/2` to set a checkpoint and then proceed after confirming delivery.
- **Ensuring Complete Data**: Useful in testing or analysis scenarios where you must be sure that no partial data sets are left unprocessed before making decisions or reporting results.

# function(Session, MFA, MatchSpec, FlagList)

The `function/4` function enables or disables call tracing for specified functions in the current trace session. Combined with `process/4` (enabling `:call` on processes), it helps you focus on particular function calls.

## Parameters

- **Session**:
  The session handle returned by `session_create/3`.

- **MFA**:
  A tuple `{Module, Function, Arity}` specifying which functions to trace.
  Wildcards:
    - `{Module, Function, '_'}` matches all arities of a given function.
    - `{Module, '_', '_'}` matches all functions in a module.
    - `{'_', '_', '_'}` matches all loaded functions.
  The atom `on_load` can also be used to apply tracing to functions in modules loaded in the future.

- **MatchSpec**:
  Controls how or if calls are traced.
  - `true`: Enable tracing without a match specification (all calls are traced).
  - `false`: Disable tracing for matching functions.
  - A match specification: Filter which calls trigger trace events.
  - `restart` or `pause`: Manage counters like call_count, call_time, or call_memory.

- **FlagList**:
  Options include:
  - `global`: Trace only global (fully qualified) calls.
  - `local`: Trace all function calls (local and global).
  - `meta`: Meta-tracing mode with fixed trace flags.
  - `call_count`, `call_time`, `call_memory`: Track performance metrics for these functions.

## Behavior

`function/4` modifies which functions are call-traced in the session. It can set or remove match specs, and switch between different tracing modes (global vs local). Pair with `process/4` enabling `:call` on target processes to see trace messages.

## Possible Responses

- Returns the number of functions affected.
- Raises errors if arguments are invalid.

## Use Cases

- **Selective Debugging**: Only trace calls to `my_module:my_function/3` to reduce noise and focus on the problematic code paths.
- **Performance Profiling**: Use `call_time` or `call_count` to gather metrics on frequently called functions, helping identify hotspots or inefficiencies in code.

# info(Session, PidPortFuncEvent, Item)

The `info/3` function retrieves trace-related information about a particular process, port, function, or event. It helps you introspect your current tracing configuration.

## Parameters

- **Session**:
  The session handle returned by `session_create/3`.

- **PidPortFuncEvent**:
  Can be:
  - A pid: Get info about that specific process.
  - A port: Get info about that specific port.
  - A function specified as `{Module, Function, Arity}` or `on_load`: Get info about function tracing.
  - Special atoms like `send`, `receive`, `new`, `new_processes`, `new_ports` for events and defaults.

- **Item**:
  Specifies what information you want.
  Options include `flags`, `tracer`, `traced`, `match_spec`, `meta`, `meta_match_spec`, `call_count`, `call_time`, `call_memory`, or `all` to get a summary.

## Behavior

`info/3` returns the requested trace configuration or statistics. For example, `flags` tells you which trace flags are set for a process. `call_count` or `call_time` may return counters for function calls if such metrics are enabled. `match_spec` returns the currently set match specification.

## Possible Responses

- If the entity exists and is traced, returns detailed information.
- If not traced or non-existent, may return `false` or `undefined`.

## Use Cases

- **Verification of Settings**: Ensure that a function or process is indeed being traced with the expected flags and match specs.
- **Retrieving Metrics**: Obtain call counts or execution times for a function to aid in performance analysis.
- **Debugging**: If tracing is not producing expected output, check `info/3` to see what’s currently configured.


# port(Session, Ports, How, FlagList)

The `port/4` function applies or removes tracing flags on one or more ports. Similar to `process/4`, but focuses on ports that can represent external resources or I/O.

## Parameters

- **Session**:
  The session handle returned by `session_create/3`.

- **Ports**:
  - A specific port identifier.
  - `all`: Apply to all current and future ports.
  - `existing`: Apply to all currently open ports.
  - `new`: Apply to any ports opened after this call.

- **How**:
  Boolean value:
  - `true` to enable the specified flags.
  - `false` to disable them.

- **FlagList**:
  Trace flags relevant to ports, such as `send`, `receive`, `ports` (process-port interaction), `running_ports` for scheduling insights, and timestamp flags.

## Behavior

`port/4` sets or clears the specified trace flags for the chosen ports. For example, enabling `:send` would trace messages sent by these ports. If `all` is chosen with `true`, all ports get these flags now and in the future.

## Possible Responses

- Returns the number of ports affected.
- Errors if arguments are invalid.

## Use Cases

- **I/O Debugging**: Trace messages passing through a port (like a TCP socket) to understand how data flows.
- **Performance Monitoring**: Track scheduling or message events on busy ports to diagnose bottlenecks or latency issues.
- **Selective Tracing**: Enable tracing only on `new` ports to monitor resources as they are created, without affecting existing stable ones.


# process(Session, Procs, How, FlagList)

The `process/4` function enables or disables trace flags on processes. It’s central to controlling what events you see, like function calls, message passing, scheduling, or garbage collection for the targeted processes.

## Parameters

- **Session**:
  The session handle returned by `session_create/3`.

- **Procs**:
  Can be:
  - A single pid to target a specific process.
  - `all`: Apply to all current and future processes.
  - `existing`: Apply to all currently running processes.
  - `new`: Apply to any processes spawned after this call.

- **How**:
  Boolean value:
  - `true` to enable the given trace flags.
  - `false` to disable them.

- **FlagList**:
  A list of flags controlling what is traced:
  - `call`: Trace function calls (combine with `function/4`).
  - `send` and `receive`: Trace message passing.
  - `running`, `running_procs`, `exiting`: Trace scheduling and process exit events.
  - `garbage_collection`: Trace garbage collection runs.
  - Timestamp flags (`timestamp`, `monotonic_timestamp`, `strict_monotonic_timestamp`) for timing info.
  - `set_on_spawn`, `set_on_first_spawn`, `set_on_link`, `set_on_first_link` for propagating trace settings to new or linked processes.
  - `silent` can suppress direct trace messages but still apply match specs.

## Behavior

`process/4` modifies the trace environment for the specified set of processes. By combining flags, you can focus on exactly the kind of runtime events you need to observe. If you later disable them, the processes return to normal operation without those traces.

## Possible Responses

- Returns the number of processes affected.
- May raise errors for invalid arguments.

## Use Cases

- **Debugging a Single Process**: Enable `:call` and `:send` on a single problematic process to see exactly which functions it calls and which messages it sends.
- **System-Wide Monitoring**: Set `all` and a broad set of flags to profile the entire system’s scheduling or message flow.
- **Granular Control**: Use `existing` and `new` to separate currently running processes from those created in the future, focusing your tracing efforts precisely.


# recv(Session, MatchSpec, FlagList)

The `recv/3` function defines how messages received by traced processes or ports are filtered and traced. To be effective, you must first enable `:'receive'` tracing on those processes or ports via `process/4` or `port/4`.

## Parameters

- **Session**:
  The session handle returned by `session_create/3`.

- **MatchSpec**:
  Controls which received messages produce trace events.
  - `true`: Trace all received messages.
  - `false`: Disable tracing of received messages.
  - A match specification: Filter messages by sender, content, or other criteria. For example, only trace messages of a certain shape or from a certain process.

- **FlagList**:
  Must be empty (`[]`) for `recv/3`.

## Behavior

`recv/3` sets a match specification that applies to received messages. When a traced process or port receives a message, it is checked against the match spec. If it matches and receive tracing is enabled, a trace event is generated.

## Possible Responses

- Always returns 1 on success.
- Raises errors if arguments are invalid.

## Use Cases

- **Selective Monitoring**: You might only care about messages that match a certain pattern, such as `{request, _}`. Use a match spec to ignore irrelevant traffic.
- **Focus on Specific Interactions**: If a process receives many types of messages, limit tracing to those crucial for debugging performance or logical errors.


# send(Session, MatchSpec, FlagList)

The `send/3` function is analogous to `recv/3` but applies to messages sent by traced processes or ports. Set `:send` tracing via `process/4` or `port/4`, then refine which sent messages are reported using `send/3`.

## Parameters

- **Session**:
  The session handle returned by `session_create/3`.

- **MatchSpec**:
  Controls which sent messages produce trace events.
  - `true`: Trace all sent messages.
  - `false`: Disable send tracing.
  - A match specification: Filter based on the receiver or message content, allowing highly targeted tracing.

- **FlagList**:
  Must be empty (`[]`).

## Behavior

Once `:send` tracing is enabled for certain processes or ports, `send/3` can focus only on specific kinds of sent messages. Non-matching messages are not traced, reducing output noise and overhead.

## Possible Responses

- Returns 1 on success.
- Errors if arguments are invalid.

## Use Cases

- **Message Flow Debugging**: In a system with many messages, focus on a particular subset, e.g., only those sent to a certain PID or matching a particular pattern.
- **Performance Analysis**: Trace only large or critical messages to understand their timing and volume without getting overwhelmed by trivial messages.


# session_info(PidPortFuncEvent)

The `session_info/1` function reports which trace sessions affect a specific process, port, function, or event. It is useful for introspection when multiple sessions run concurrently.

## Parameters

- **PidPortFuncEvent**:
  Could be:
  - A PID or port to see which sessions are tracing it.
  - `{Module, Function, Arity}` or `on_load` to see which sessions affect this function tracing.
  - `all`, `new`, `new_processes`, `new_ports`, `send`, `receive` for those respective categories.

## Behavior

`session_info/1` returns a list of session weak references that currently apply to the given entity or event. If none apply, it may return `undefined`.

Weak references do not keep sessions alive on their own. They simply report that these sessions have some influence on the specified entity.

## Possible Responses

- A list of session references if sessions are tracing the given entity or event.
- `undefined` if the entity is not traced by any session.

## Use Cases

- **Conflict Resolution**: Check which sessions are tracing a particular process if multiple teams or tools are operating on the same node.
- **Introspection**: Determine why you’re receiving certain trace messages by identifying all sessions impacting a function or port.
- **System Transparency**: Gain visibility into the current tracing landscape of your node.
