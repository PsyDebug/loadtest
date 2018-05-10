-module(loadtest).
-export([gunUrl/1]).

-define(LOG(_Url,Time,Stat),io:format(" response time: ~p Code: ~p~n ", [Time, Stat])).
-define(LOG(Url),io:format(" no cookies for url: ~p~n ", [Url])).
-define(LOGIN_ACTION,"/login/Login.do").
-define(LOG(Url,Error),io:format("Error:~p for url: ~p~n ", [Error,Url])).

gunUrl([Client,Url]) ->
    {ok,{http,_,_IP, _Port, Pref, _Req}}=http_uri:parse(Url),
    case Pref of
        ?LOGIN_ACTION ->
            case timer:tc(fun() -> httpc:request(get, {Url, []}, [], []) end) of
                {Time,{ok, {{_Version, Stat, _ReasonPhrase}, Headers, _Body}}}-> ?LOG(Url,Time/1000000,Stat),
                                     ets:insert(cookies,{Client, proplists:get_value("set-cookie",Headers)});
                Error       ->       ?LOG(Url,Error)
            end;
        _      ->
            case ets:lookup(cookies,Client) of
                [{_,Cookies}]->
                    case  timer:tc(fun() -> httpc:request(get, {Url, [{"Cookie",Cookies}]}, [], []) end) of
                      {Time,{ok, {{_Version, Stat, _ReasonPhrase}, _Headers, _Body}}}-> ?LOG(Url,Time/1000000,Stat);
                        Error       ->       ?LOG(Url,Error)
                    end;
                _ -> ?LOG(Url)
            end
    end.


