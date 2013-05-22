-module(base64url_tests).
-include_lib("eunit/include/eunit.hrl").

id(X) ->
    ?assertEqual(
       X,
       base64url:decode(base64url:encode(X))),
    ?assertEqual(
       X,
       base64url:decode(
         binary_to_list(base64url:encode(binary_to_list(X))))).

random_binary(Short,Long) ->
    << <<(random:uniform(256) - 1)>>
     || _ <- lists:seq(1, Short + random:uniform(1 + Long - Short) - 1) >>.

empty_test() ->
    id(<<>>).

onechar_test() ->
    [id(<<C>>) || C <- lists:seq(0,255)],
    ok.

nchar_test() ->
    %% 1000 tests of 2-6 char strings
    [id(B) || _ <- lists:seq(1,1000), B <- [random_binary(2, 6)]],
    ok.

term_test() ->
    T = {foo, bar},
    ?assertEqual(T, base64url:decode_term(base64url:encode_term(T))),
    ok.

is_base64url_test_() ->
    [ ?_assertEqual(true,  base64url:is_base64url("adsf-"))
    , ?_assertEqual(false, base64url:is_base64url("123+"))
    , ?_assertEqual(true,  base64url:is_base64url(<<"12345__">>))
    , ?_assertEqual(false, base64url:is_base64url(<<"fda ///">>))
    ].
