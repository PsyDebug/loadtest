-module(gun_url).
-behaviour(gen_server).

-export([start/1, start/0, stop/0, pause/0, change_limits/1]).
-export([init/1, terminate/2, handle_cast/2, handle_call/3]).

start(Limits) ->
  gen_server:start_link({global, ?MODULE}, ?MODULE, Limits, []).

init(Limits)->
    inets:start(),
    ets:new(cookies,[set, public, {keypos, 1}, named_table]),
    read_url:start(),
    Pids=lists:map(fun({ok,Pid})->Pid end, [gun_worker:start() || _X<-lists:seq(1,Limits)]),
    {ok,Pids}.

start()->
    gen_server:cast(?MODULE, run_task).

pause()->
    gen_server:cast(?MODULE, pause).

stop()->
    gen_server:cast(?MODULE, stop).

change_limits(Limits)->
    gen_server:call(gun_url, {change,Limits}).

handle_cast(run_task,Pids)->
    _F=lists:map(fun(Pid)->gun_worker:go(Pid) end,Pids),
    {noreply,Pids};

handle_cast(pause,Pids)->
    lists:map(fun(Pid)->gun_worker:pause(Pid) end,Pids),
    {noreply,Pids};

handle_cast(stop, Pids)->
    lists:map(fun(Pid)->gun_worker:stop(Pid) end,Pids),
    inets:stop(),
    read_url:stop(),
    {stop, normal, []}.

handle_call({change,Limits},_From,Pids)->
    lists:map(fun(Pid)->gun_worker:stop(Pid) end,Pids),
    PidsNew=lists:map(fun({ok,Pid})->Pid end, [gun_worker:start() || _X<-lists:seq(1,Limits)]),
    {reply,"Limits has changed. You can run jobs.",PidsNew}.

 
terminate(_Reason, Pids) ->
    lists:map(fun(Pid)->gun_worker:stop(Pid) end,Pids),
    ets:delete(cookies),
    inets:stop(),
    read_url:stop(),
    ok.


