%%%
%%% @doc Handle http requests.
%%%

-module(ar_http_iface_server).

-export([start/5]).
-export([reregister/1, reregister/2]).

-include("ar.hrl").
-include_lib("eunit/include/eunit.hrl").

%%%
%%% Public API.
%%%

%% @doc Start the Arweave HTTP API and returns a process ID.
start(Port, Node, SearchNode, ServiceNode, BridgeNode) ->
	reregister(http_entrypoint_node, Node),
	reregister(http_search_node, SearchNode),
	reregister(http_service_node, ServiceNode),
	reregister(http_bridge_node, BridgeNode),
	do_start(Port).

%% @doc Helper function : registers a new node as the entrypoint.
reregister(Node) ->
	reregister(http_entrypoint_node, Node).
reregister(_, undefined) -> not_registering;
reregister(Name, Node) ->
	case erlang:whereis(Name) of
		undefined -> do_nothing;
		_ -> erlang:unregister(Name)
	end,
	erlang:register(Name, Node).

%%%
%%% Private functions
%%%

%% @doc Start the server
do_start(Port) ->
	spawn(
		fun() ->
			ProtocolOpts =
				#{
					middlewares => [cowboy_handler],
					env => #{
						handler => ar_http_iface_cowboy_handler,
						handler_opts => []
					}
				},

			{ok, _} =
				cowboy:start_clear(
					ar_cowboy_listener,
					[{port, Port}],
					ProtocolOpts
				),
			receive
				stop -> cowboy:stop_listener(ar_cowboy_listener)
			end
		end
	).
