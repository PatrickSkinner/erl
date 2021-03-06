-module(service).
-export([service/0, receiver/2]).

service() ->
	MR = spawn(?MODULE, receiver, [ [], [] ] ),
	global:register_name(service, MR).
	
receiver(Clients, Auctions) ->
	receive
		{client_add, Id, Interests} ->
			NewClients = [{Id, Interests} | Clients],
			io:format("Client Added~n"),
			
			broadcastClient({Id, Interests}, Auctions),
			receiver(NewClients, Auctions);
			
		{client_remove, Id, Interests} ->
			NewClients = lists:keydelete(Id, 1, Clients),
			io:format("Client Removed~n"),
			
			receiver(NewClients, Auctions);
			
		{auction_add, Id, Interests} ->
			NewAuctions = [{Id, Interests} | Auctions],
			io:format("Auction Added~n"),
			
			broadcastAuction( {Id, Interests}, Clients),
			timer:send_after(30*1000, Id, {end_auction}),
			receiver(Clients, NewAuctions);
			
		{auction_remove, Id} ->
			NewAuctions = lists:keydelete(Id, 1, Auctions),
			io:format("Auction Removed~n"),
			
			receiver(Clients, NewAuctions)
			
	end.
	
broadcastClient( Client, []) ->
	ok;
broadcastClient( Client, Auctions ) ->
	[Auction |Tail] = Auctions,
	
	Match = lists:member(element(2, Auction), element(2, Client) ),
	
	if
		Match /= false ->
			element(1, Auction) ! {client_add, Client},
			broadcastClient( Client, Tail);
		true ->
			broadcastClient( Client, Tail)
	end.
	
broadcastAuction(Auction, [])->
	ok;
broadcastAuction(Auction, Clients)->
	[Client |Tail] = Clients,
	Match = lists:member(element(2, Auction), element(2, Client) ),
	
	if
		Match /= false ->
			element(1, Auction) ! {client_add, Client},
			broadcastClient( Client, Tail);
		true ->
			broadcastClient( Client, Tail)
	end.
	
