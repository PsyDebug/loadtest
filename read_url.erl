-module(read_url).
-behaviour(gen_server).

-export([start/0, stop/0, getUrl/0]).
-export([init/1, terminate/2, handle_call/3, handle_cast/2]).

-define(GUN_FILE,"forgun.log").

start() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([])->
    file:open(?GUN_FILE, read).

stop()->
    gen_server:cast(?MODULE,stop).

getUrl()->
    gen_server:call(?MODULE,get_url).

handle_call(get_url,_From,State)->
    Url=io:get_line(State, ''),
    {reply,Url,State}.

handle_cast(stop,State)->
    file:close(State),
    {stop,normal,State}.

terminate(_Reason, _State) ->  ok.

