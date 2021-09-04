%%%-------------------------------------------------------------------
%% @doc quadtree.
%% @end
%%%-------------------------------------------------------------------

-module(quadtree_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("quadtree.hrl").

-spec basic_test() -> 'ok'.
basic_test() ->
    Q1 = quadtree:new({rectangle, 0, 0, 100, 100}),
    Q2 = qt_put(Q1, 2000),
    Items = quadtree:query({rectangle, 20, 20, 50, 50}, Q2),
    ?assert(length(Items) > 0),
    ok.

-spec put_and_subdivide_test() -> 'ok'.
put_and_subdivide_test() ->
    Q1 = quadtree:new({rectangle, 0, 0, 200, 200}, #{max_items => 1}),
    Q2 = quadtree:put({{point, 10, 10}, #{}}, Q1),
    Q3 = quadtree:put({{point, 110, 10}, #{}}, Q2),
    Q4 = quadtree:put({{point, 110, 110}, #{}}, Q3),
    #qtnode{
        x = 0,
        y = 0,
        width = 200,
        height = 200,
        items = [{{point, 10, 10}, #{}}],
        children = Children,
        options = _Options
    } = quadtree:put({{point, 10, 110}, #{}}, Q4),
    [C1, C2, C3, C4] = Children,
    ?assertEqual(
        #qtnode{
            x = 0,
            y = 0,
            width = 100.0,
            height = 100.0,
            items = [{{point, 10, 10}, #{}}],
            children = [],
            options = #{
                max_items => 1,
                max_depth => 20,
                depth => 1
            }
        },
        C1
    ),
    ?assertEqual(
        #qtnode{
            x = 100.0,
            y = 0,
            width = 100.0,
            height = 100.0,
            items = [{{point, 110, 10}, #{}}],
            children = [],
            options = #{
                max_items => 1,
                max_depth => 20,
                depth => 1
            }
        }, C2
    ),
    ?assertEqual(
        #qtnode{
            x = 100.0,
            y = 100.0,
            width = 100.0,
            height = 100.0,
            items = [{{point, 110, 110}, #{}}],
            children = [],
            options = #{
                max_items => 1,
                max_depth => 20,
                depth => 1
            }
        }, C3
    ),
    ?assertEqual(
        #qtnode{
            x = 0,
            y = 100.0,
            width = 100.0,
            height = 100.0,
            items = [{{point, 10, 110}, #{}}],
            children = [],
            options = #{
                max_items => 1,
                max_depth => 20,
                depth => 1
            }
        }, C4
    ),
    ok.

-spec query_test() -> 'ok'.
query_test() ->
    Q1 = quadtree:new({rectangle, 0, 0, 200, 200}, #{max_items => 1}),
    Q2 = quadtree:put({{point, 10, 10}, #{}}, Q1),
    Q3 = quadtree:put({{point, 110, 10}, #{}}, Q2),
    Q4 = quadtree:put({{point, 110, 110}, #{}}, Q3),
    Q5 = quadtree:put({{point, 10, 110}, #{}}, Q4),

    Items1 = quadtree:query({rectangle, 0, 0, 200, 200}, Q5),
    ?assertEqual(4, length(Items1)),
    ?assert(lists:member({{point, 10, 10}, #{}}, Items1)),
    ?assert(lists:member({{point, 110, 10}, #{}}, Items1)),
    ?assert(lists:member({{point, 110, 110}, #{}}, Items1)),
    ?assert(lists:member({{point, 10, 110}, #{}}, Items1)),

    Items2 = quadtree:query({rectangle, 10, 0, 20, 20}, Q5),
    ?assertEqual(1, length(Items2)),
    ?assertEqual([{{point, 10, 10}, #{}}], Items2),

    Items3 = quadtree:query({rectangle, 0, 0, 200, 100}, Q5),
    ?assertEqual(2, length(Items3)),
    ?assert(lists:member({{point, 10, 10}, #{}}, Items3)),
    ?assert(lists:member({{point, 110, 10}, #{}}, Items3)),

    Items4 = quadtree:query({rectangle, 0, 100, 200, 100}, Q5),
    ?assertEqual(2, length(Items4)),
    ?assert(lists:member({{point, 110, 110}, #{}}, Items4)),
    ?assert(lists:member({{point, 10, 110}, #{}}, Items4)),

    Items5 = quadtree:query({rectangle, 0, 0, 0, 0}, Q5),
    ?assertEqual(0, length(Items5)),

    Items6 = quadtree:query({rectangle, 200, 200, 200, 200}, Q5),
    ?assertEqual(0, length(Items6)),

    Items7 = quadtree:query({rectangle, 100, 100, 100, 100}, Q5),
    ?assertEqual(1, length(Items7)),
    ?assertEqual([{{point, 110, 110}, #{}}], Items7),
    ok.

-spec collision_detection_test() -> 'ok'.
collision_detection_test() ->
    Q1 = quadtree:new({rectangle, 0, 0, 500, 500}),
    Q2 = quadtree:put({{point, 0, 10}, p1}, Q1),
    Q3 = quadtree:put({{point, 0, 10}, p2}, Q2),
    Q4 = quadtree:put({{point, 150, 150}, p3}, Q3),
    Q5 = quadtree:put({{point, 152, 152}, p4}, Q4),
    Q6 = quadtree:put({{point, 100, 100}, p5}, Q5),

    Range1 = {rectangle, 0 - 3, 10 - 3, 2 * 3, 2 * 3},
    CollisedDetection1 = quadtree:query(Range1, Q6),
    ?assertEqual(2, length(CollisedDetection1)),
    ?assert(lists:member({{point, 0, 10}, p1}, CollisedDetection1)),
    ?assert(lists:member({{point, 0, 10}, p2}, CollisedDetection1)),

    Range2 = {rectangle, 150 - 3, 150 - 3, 2 * 3, 2 * 3},
    CollisedDetection2 = quadtree:query(Range2, Q6),
    ?assertEqual(2, length(CollisedDetection2)),
    ?assert(lists:member({{point, 150, 150}, p3}, CollisedDetection2)),
    ?assert(lists:member({{point, 152, 152}, p4}, CollisedDetection2)),

    Range3 = {rectangle, 100 - 3, 100 - 3, 2 * 3, 2 * 3},
    CollisedDetection3 = quadtree:query(Range3, Q6),
    ?assertEqual(1, length(CollisedDetection3)),
    ?assert(lists:member({{point, 100, 100}, p5}, CollisedDetection3)),
    ok.

%% ===================================================================
%% Helper functions
%% ===================================================================

-spec qt_put(qtnode(), integer()) -> qtnode().
qt_put(Quadtree, 0) ->
    Quadtree;
qt_put(Quadtree, N) ->
    qt_put(quadtree:put(new_item(Quadtree), Quadtree), N - 1).

-spec new_item(qtnode()) -> item(map()).
new_item(#qtnode{x = X, y = Y, width = Width, height = Height} = _Quadtree) ->
    {{point, rand:uniform(Width - X), rand:uniform(Height - Y)}, #{}}.
