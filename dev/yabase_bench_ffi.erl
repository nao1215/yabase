-module(yabase_bench_ffi).
-export([now_ms/0, case_name/0]).
now_ms() -> erlang:monotonic_time(millisecond).
case_name() -> case os:getenv("YB_CASE") of false -> <<>>; V -> unicode:characters_to_binary(V) end.
