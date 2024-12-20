Erlang trace Module Function Overview
This document summarizes each of the key functions provided by the new Erlang trace module interface introduced in OTP 27.0. These functions operate within dynamically created trace sessions, allowing multiple independent and isolated tracing activities on the same node.

A trace session is created with session_create/3, providing a tracer that receives or processes trace events. Once created, you can attach trace flags and match specifications to processes, ports, functions, and message patterns. When done, session_destroy/1 cleans up all applied trace settings.

session_create(Name, Tracer, Opts)
Creates a new, isolated trace session.

Parameters: • Name: An atom naming the session, used for identification. • Tracer: The consumer of trace events. Can be a PID (process), port, or a tracer module in the form {Module, State}. • Opts: Must be an empty list (no options currently defined).

Behavior: Returns a session handle that keeps the session alive. Multiple sessions can coexist without interfering with each other.

Use case: Start a trace session for debugging, profiling, or monitoring a subset of processes or functions without affecting other sessions or normal operation.

session_destroy(Session)
Destroys a previously created trace session and cleans up associated trace settings.

Parameters: • Session: The handle returned by session_create/3.

Behavior: Returns true if the session was active and is now destroyed, false if it was already destroyed.

Use case: End tracing cleanly when finished analyzing runtime behavior.

session_info(PidPortFuncEvent)
Returns which sessions affect a given process, port, function, or event category.

Parameters: • PidPortFuncEvent: Can be a pid, port, a tuple {Module, Function, Arity}, or special atoms like all, new, new_processes, new_ports, on_load, send, receive.

Behavior: Returns a list of session weak references if tracing is active for that entity/event, or undefined otherwise.

Use case: Check if a particular entity (process, port, function) or event (like send or receive) is currently being traced by any sessions.

delivered(Session, Tracee)
Equivalent to erlang:trace_delivered(Tracee) but scoped to a specific session.

Parameters: • Session: The trace session handle. • Tracee: A pid or the atom all.

Behavior: Returns a reference that can be used to determine when all trace messages up to this point have been delivered to the tracer.

Use case: Synchronize with the tracer, ensuring all previously emitted trace events have been processed.

process(Session, Procs, How, FlagList)
Enable or disable trace flags on one or more processes.

Parameters: • Session: The session handle. • Procs: A pid, or the atoms all, existing, new. all targets all current and future processes, existing targets currently running processes, new targets any processes created after this call. • How: A boolean (true/false). true enables the flags, false disables them. • FlagList: A list of trace flags, such as call, send, receive, running, garbage_collection, timestamp variants, and inheritance flags like set_on_spawn.

Behavior: Sets or clears trace flags for the selected processes. Returns the number of affected processes.

Use case: Focus on a particular process or group of processes, enabling tracing of their function calls, messages, scheduling, and more.

port(Session, Ports, How, FlagList)
Similar to process/4 but applies to ports.

Parameters: • Session: The session handle. • Ports: A specific port, or all, existing, new for targeting multiple ports. • How: true or false to enable or disable trace flags. • FlagList: Similar flags as for processes, but port-related events (like open, closed, and scheduling) and message tracing apply to ports.

Behavior: Sets or clears trace flags for the selected ports. Returns the number of affected ports.

Use case: Monitor external resources (file descriptors, network sockets) by tracing their message traffic and scheduling.

function(Session, MFA, MatchSpec, FlagList)
Enable or disable call tracing on one or more functions. Must be combined with process/4 calls that enable :call on processes to actually produce call trace messages.

Parameters: • Session: The session handle. • MFA: A tuple {Module, Function, Arity} or wildcards. Also can use on_load to affect functions of modules that will be loaded in the future. • MatchSpec: A match specification or boolean controlling what calls get traced.

true: enable call tracing without a match spec.
false: disable call tracing.
A match spec can filter which calls are traced.
restart/pause for counters like call_time or call_count. • FlagList: Options like global, local, meta, call_count, call_time, call_memory. global or local tracing controls how and when calls are traced. meta sets up a meta-tracer. call_count/time/memory enable performance metrics.
Behavior: Adjusts which functions are call-traced in the session. Returns the number of functions affected.

Use case: Profile or debug specific functions, count how often they are called, measure execution time or memory usage, or capture their call arguments.

send(Session, MatchSpec, FlagList)
Filter and control tracing of messages sent by traced processes or ports.

Parameters: • Session: The session handle. • MatchSpec: true to trace all sent messages, false to disable, or a match specification to selectively trace messages based on their content and receiver. • FlagList: Must be empty.

Behavior: Determines which sent messages produce trace events. Works only if the sending process/port has send tracing enabled via process/4 or port/4.

Use case: Narrow down message tracing to specific patterns, such as only certain message types or recipients.

recv(Session, MatchSpec, FlagList)
Similar to send/3 but for messages received by traced processes or ports.

Parameters: • Session: The session handle. • MatchSpec: Same semantics as for send. true, false, or a match specification to filter received messages. • FlagList: Must be empty.

Behavior: Controls which received messages are traced. Requires receive tracing to be enabled on processes/ports.

Use case: Focus on certain incoming messages to debug inter-process communication patterns without flooding the tracer with irrelevant data.

info(Session, PidPortFuncEvent, Item)
Retrieve trace information for a port, process, function, or event.

Parameters: • Session: The session handle. • PidPortFuncEvent: The entity or event you want info about. • Item: flags, tracer, traced, match_spec, meta, meta_match_spec, call_count, call_time, call_memory, or all.

Behavior: Returns detailed trace configuration and performance counters for the specified entity. For functions, it can return match specs, whether the function is traced locally or globally, and performance data. For processes/ports, it can show which flags are active.

Use case: Introspect and verify current tracing configuration and metrics, confirming that your tracing setup is as intended.

In summary, these functions let you: • Create and destroy isolated trace sessions (session_create, session_destroy). • Configure tracing for processes, ports, functions, and message patterns (process, port, function, send, recv). • Retrieve and inspect trace settings and statistics (info, session_info). • Synchronize and ensure delivery of trace messages (delivered).

These tools are essential for advanced debugging, performance profiling, and monitoring of Erlang systems, allowing you to precisely target the events and entities you need to examine while leaving the rest of the system unaffected.
