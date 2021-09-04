%%%-------------------------------------------------------------------
%% @doc quadtree.
%% @end
%%%-------------------------------------------------------------------

-module(quadtree).

-export([new/1, new/2, put/2, query/2]).

-include_lib("quadtree.hrl").

%%====================================================================
%% Public API
%%====================================================================

-spec new(Boundary) -> Quadtree when
    Boundary :: rectangle(),
    Quadtree :: qtnode().
new({rectangle, _X, _Y, _Width, _Height} = Boundary) ->
    new(Boundary, default_options()).

-spec new(Boundary, Options) -> Quadtree when
    Boundary :: rectangle(),
    Options :: map(),
    Quadtree :: qtnode().
new({rectangle, X, Y, Width, Height}, Options) ->
    #qtnode{
        x = X,
        y = Y,
        width = Width,
        height = Height,
        options = default_options(Options)
    }.

-spec put(Items, Quadtree) -> Quadtree when
    Items :: Item | list(Item),
    Item :: item(TItem),
    TItem :: any(),
    Quadtree :: qtnode().
put({{point, _X, _Y}, _}  = Item, Quadtree0) ->
    case contains(Item, Quadtree0) of
        true ->
            Depth = maps:get(depth, Quadtree0#qtnode.options),
            MaxDepth = maps:get(max_depth, Quadtree0#qtnode.options),
            MaxItems = maps:get(max_items, Quadtree0#qtnode.options),
            case (length(Quadtree0#qtnode.items) < MaxItems) and
                 (Depth < MaxDepth) of
                true ->
                    Quadtree0#qtnode{
                        items = [Item | Quadtree0#qtnode.items]
                    };
                false ->
                    Quadtree = case length(Quadtree0#qtnode.children) == 0 of
                        true ->
                            Items = Quadtree0#qtnode.items,
                            Quadtree1 = subdivide(Quadtree0),
                            Quadtree1#qtnode{
                                children = [quadtree:put(Items, C) || C <- Quadtree1#qtnode.children]
                            };
                        false ->
                            Quadtree0
                    end,
                    Quadtree#qtnode{children = [quadtree:put(Item, C) || C <- Quadtree#qtnode.children]}
            end;
        false ->
            Quadtree0
    end;
put([], Quadtree) ->
    Quadtree;
put([Item | Items], Quadtree) ->
    quadtree:put(Items, quadtree:put(Item, Quadtree)).

-spec query(Boundary, Quadtree) -> Items when
    Boundary :: rectangle(),
    Quadtree :: qtnode(),
    Items :: list(Item),
    Item :: item(TItem),
    TItem :: any().
query({rectangle, _X, _Y, _W, _H} = Range, #qtnode{items = Items, children = []}) ->
    {_List, AccOut} = lists:mapfoldl(fun(Item, AccIn) ->
        case contains(Item, Range) of
            true ->
                {true, AccIn ++ [Item]};
            false ->
                {false, AccIn}
        end
    end, [], Items),
    AccOut;
query(Range, #qtnode{children = Children} = Quadtree) ->
    case intersects(Range, Quadtree) of
        true ->
            lists:foldl(fun(Child, AccIn) ->
                AccIn ++ query(Range, Child)
            end, [], Children);
        false ->
            []
    end.

%%====================================================================
%% Internal functions
%%====================================================================

-spec contains(Item, Object) -> Result when
    Item :: item(TItem),
    TItem :: any(),
    Object :: Rectangle | Quadtree,
    Rectangle :: rectangle(),
    Quadtree :: qtnode(),
    Result :: boolean().
contains({{point, _X, _Y}, _} = Item, #qtnode{x = X, y = Y, width = Width, height = Height}) ->
    contains(Item, {rectangle, X, Y, Width, Height});
contains({{point, X1, Y1}, _}, {rectangle, X2, Y2, W2, H2}) ->
    (
        (X1 >= X2) and
        (X1 =< X2 + W2) and
        (Y1 >= Y2) and
        (Y1 =< Y2 + H2)
    ).

-spec intersects(Rectangle, Quadtree) -> Result when
    Rectangle :: rectangle(),
    Quadtree :: qtnode(),
    Result :: boolean();
                (Rectangle, Rectangle) -> Result when
    Rectangle :: rectangle(),
    Result :: boolean().
intersects({rectangle, _X, _Y, _W, _H} = Rectangle, #qtnode{x = X, y = Y, width = Width, height = Height}) ->
    intersects(Rectangle, {rectangle, X, Y, Width, Height});
intersects({rectangle, X1, Y1, W1, H1}, {rectangle, X2, Y2, W2, H2}) ->
    (
        (X1 < X2 + W2) and
        (X1 + W1 > X2) and
        (Y1 < Y2 + H2) and
        (Y1 + H1 > Y2)
    ).

-spec subdivide(Quadtree) -> Quadtree when
    Quadtree :: qtnode().
subdivide(#qtnode{x = X, y = Y, width = Width, height = Height} = Quadtree0) ->
    W = Width / 2,
    H = Height / 2,
    Options = Quadtree0#qtnode.options,
    NewOptions = Options#{depth := maps:get(depth, Quadtree0#qtnode.options) + 1},
    NorthEast = new({rectangle, X, Y, W, H}, NewOptions),
    NorthWest = new({rectangle, X + W, Y, W, H}, NewOptions),
    SouthWest = new({rectangle, X + W, Y + H, W, H}, NewOptions),
    SouthEast = new({rectangle, X, Y + H, W, H}, NewOptions),
    Quadtree0#qtnode{
        children = [NorthEast, NorthWest, SouthWest, SouthEast]
    }.

-spec default_options() -> Options when
    Options :: map().
default_options() ->
    default_options(#{}).

-spec default_options(Options) -> Options when
    Options :: map().
default_options(Options) ->
    #{
        max_items => maps:get(max_items, Options, 25),
        max_depth => maps:get(max_depth, Options, 20),
        depth => maps:get(depth, Options, 0)
    }.

%%====================================================================
%% Test functions
%%====================================================================

-ifdef(EUNIT).
-include_lib("eunit/include/eunit.hrl").

-spec contains_test() -> 'ok'.
contains_test() ->
    ?assert(contains({{point, 0, 0}, #{}}, {rectangle, 0, 0, 100.0, 100.0})),
    ?assert(contains({{point, 10, 10}, #{}}, {rectangle, 0, 0, 100, 100})),
    ?assert(contains({{point, 10, 10}, #{}}, {rectangle, 0, 0, 100.0, 100.0})),
    ?assert(contains({{point, 100, 100}, #{}}, {rectangle, 0, 0, 100.0, 100.0})),
    ?assertNot(contains({{point, 101, 100}, #{}}, {rectangle, 0, 0, 100, 100})),
    ?assertNot(contains({{point, 100, 101}, #{}}, {rectangle, 0, 0, 100, 100})),
    ?assertNot(contains({{point, 101, 101}, #{}}, {rectangle, 0, 0, 100, 100})),
    ?assertNot(contains({{point, 10, 10}, #{}}, {rectangle, 100, 0, 100, 100})),
    ?assert(contains({{point, 110, 10}, #{}}, {rectangle, 100.0, 0, 100.0, 100.0})),
    ?assert(contains({{point, 110, 110}, #{}}, {rectangle, 100.0, 100.0, 100.0, 100.0})),
    ?assertNot(contains({{point, 110, 110}, #{}}, {rectangle, 0, 0, 100.0, 100.0})),
    ?assert(contains({{point, 10, 110}, #{}}, {rectangle, 0, 100.0, 100.0, 100.0})),
    ?assert(contains({{point, 100, 100}, #{}}, {rectangle, 100 - 3, 100 - 3, 2 * 3, 2 * 3})),
    ?assertNot(contains({{point, 150, 150}, #{}}, {rectangle, 100 - 3, 100 - 3, 2 * 3, 2 * 3})),
    ?assertNot(contains({{point, 152, 152}, #{}}, {rectangle, 100 - 3, 100 - 3, 2 * 3, 2 * 3})),
    ok.

-spec intersects_test() -> 'ok'.
intersects_test() ->
    ?assert(intersects({rectangle, 5, 5, 50, 50}, #qtnode{x = 20, y = 10, width = 10, height = 10, options = #{}})),
    ?assert(intersects({rectangle, 5, 5, 50, 50}, {rectangle, 20, 10, 10, 10})),
    ?assert(intersects({rectangle, 5, 5, 50, 50}, {rectangle, 5, 5, 50, 50})),
    ?assertNot(intersects({rectangle, 5, 5, 50, 50}, {rectangle, 55, 55, 50, 50})),
    ok.

-spec subdivide_test() -> 'ok'.
subdivide_test() ->
    NewOptions = #{max_items => 25, max_depth => 20, depth => 1},
    NorthEast = #qtnode{x = 0, y = 0, width = 50.0, height = 50.0, options = NewOptions},
    NorthWest = #qtnode{x = 50.0, y = 0, width = 50.0, height = 50.0, options = NewOptions},
    SouthWest = #qtnode{x = 50.0, y = 50.0, width = 50.0, height = 50.0, options = NewOptions},
    SouthEast = #qtnode{x = 0, y = 50.0, width = 50.0, height = 50.0, options = NewOptions},
    ?assertEqual(
        #qtnode{
            x = 0,
            y = 0,
            width = 100,
            height = 100,
            items = [],
            children = [NorthEast, NorthWest, SouthWest, SouthEast],
            options = #{
                depth => 0
            }
        },
        subdivide(#qtnode{x = 0, y = 0, width = 100, height = 100, options = #{depth => 0}})
    ),
    ok.

-spec default_options_test() -> 'ok'.
default_options_test() ->
    ?assertEqual(#{max_items => 25, max_depth => 20, depth => 0}, default_options()),
    ?assertEqual(#{max_items => 25, max_depth => 20, depth => 1}, default_options(#{depth => 1})),
    ok.

-endif.
