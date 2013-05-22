%% @doc URL and filename safe base64 variant with no padding,
%% also known as "base64url" per RFC 4648.
%%
%% This differs from base64 in the following ways:
%% '-' is used in place of '+' (62),
%% '_' is used in place of '/' (63),
%% padding is implicit rather than explicit ('=').
-module(base64url).

-export([ decode/1
        , decode_term/1
        , encode/1
        , encode_term/1
        , is_base64url/1
        ]).

-spec encode(iolist()) -> binary().
encode(B) when is_binary(B) ->
    encode_binary(B);
encode(L) when is_list(L) ->
    encode_binary(iolist_to_binary(L)).

-spec encode_term(term()) -> binary().
encode_term(T) ->
    encode(term_to_binary(T)).

-spec decode(iolist()) -> binary().
decode(B) when is_binary(B) ->
    decode_binary(B);
decode(L) when is_list(L) ->
    decode_binary(iolist_to_binary(L)).

-spec decode_term(binary()) -> term().
decode_term(B) ->
    binary_to_term(decode(B)).

%% Implementation, derived from stdlib base64.erl

%% One-based decode map.
-define(DECODE_MAP,
        {bad,bad,bad,bad,bad,bad,bad,bad,ws,ws,bad,bad,ws,bad,bad, %1-15
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad, %16-31
         ws,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,62,bad,bad, %32-47
         52,53,54,55,56,57,58,59,60,61,bad,bad,bad,bad,bad,bad, %48-63
         bad,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14, %64-79
         15,16,17,18,19,20,21,22,23,24,25,bad,bad,bad,bad,63, %80-95
         bad,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40, %96-111
         41,42,43,44,45,46,47,48,49,50,51,bad,bad,bad,bad,bad, %112-127
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
         bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad}).

encode_binary(Bin) ->
    Split = 3*(byte_size(Bin) div 3),
    <<Main0:Split/binary,Rest/binary>> = Bin,
    Main = << <<(b64e(C)):8>> || <<C:6>> <= Main0 >>,
    case Rest of
        <<A:6,B:6,C:4>> ->
            <<Main/binary,(b64e(A)):8,(b64e(B)):8,(b64e(C bsl 2)):8>>;
        <<A:6,B:2>> ->
            <<Main/binary,(b64e(A)):8,(b64e(B bsl 4)):8>>;
        <<>> ->
            Main
    end.

decode_binary(Bin) ->
    Main = << <<(b64d(C)):6>> || <<C>> <= Bin,
                                 (C =/= $\t andalso C =/= $\s andalso
                                  C =/= $\r andalso C =/= $\n) >>,
    case bit_size(Main) rem 8 of
        0 ->
            Main;
        N ->
            Split = byte_size(Main) - 1,
            <<Result:Split/bytes, _:N>> = Main,
            Result
    end.

%% accessors

b64e(X) ->
    element(X+1,
            {$A, $B, $C, $D, $E, $F, $G, $H, $I, $J, $K, $L, $M, $N,
             $O, $P, $Q, $R, $S, $T, $U, $V, $W, $X, $Y, $Z,
             $a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n,
             $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z,
             $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $-, $_}).

b64d(X) ->
    b64d_ok(element(X, ?DECODE_MAP)).

b64d_ok(I) when is_integer(I) -> I.

b64d_is(I) when is_integer(I) ->
    element(I, ?DECODE_MAP) =/= bad;
b64d_is(_) -> false.


is_base64url(B) when is_binary(B) ->
    is_base64url(binary_to_list(B));
is_base64url(L) when is_list(L) ->
    lists:all(fun b64d_is/1, lists:flatten(L)).
