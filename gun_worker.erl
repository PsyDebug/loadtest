-module(gun_worker).
-behaviour(gen_server).

-export([start/0,stop/1,pause/1,go/1,init/1]).
-export([terminate/2,handle_cast/2]).
-define(SERV,"http://172.16.2.99:81").

start()->
    gen_server:start_link(?MODULE,[],[]).

init([])->
    {ok,"on"}.

stop(Pid)->
    gen_server:cast(Pid,"stop").

pause(Pid)->
     gen_server:cast(Pid,"pause").

go(Pid)->
     gen_server:cast(Pid,"go").

handle_cast("pause","on")->
    {noreply,"off"};

handle_cast("pause","off")->
    gun_worker:go(self()),
    {noreply,"on"};

handle_cast("stop",_State)->
    {stop,normal,[]};

handle_cast("go","off")->
    {noreply,"off"};

handle_cast("go","on") ->
    %%timer:sleep(500),
    case read_url:getUrl() of
        eof -> gun_worker:stop(self());
        Row ->[Client,Url]=re:split(Row, ";", [{return, list},{parts,2}]),
              loadtest:gunUrl([Client,string:concat(?SERV,lists:droplast(Url))])
    end,
    gun_worker:go(self()),
    {noreply,"on"}.

terminate(_Reason, _State)->
    ok.



%% Pids=[recur:start() || X<-lists:seq(1,3)].
%% lists:map(fun({ok,Pid})->recur:pause(Pid) end,Pids).
