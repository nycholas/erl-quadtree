%%%-------------------------------------------------------------------
%% @doc quadtree.
%% @end
%%%-------------------------------------------------------------------

-record(qtnode, {
    x :: X :: number(),
    y :: Y :: number(),
    width :: Width :: number(),
    height :: Height :: number(),
    items = [] :: Items :: list(),
    children = [] :: Children :: list(),
    options :: Options :: map()
}).
-type qtnode() :: Quadtree :: #qtnode{}.
-export_type([qtnode/0]).

-type rectangle() :: Rectangle :: {
    'rectangle',
    X :: number(),
    Y :: number(),
    Width :: number(),
    Height :: number()
}.
-export_type([rectangle/0]).

-type point() :: Point :: {
    'point',
    X :: number(),
    Y :: number()
}.
-export_type([point/0]).

-type item(DataType) :: Item :: {
    Point :: point(),
    Data :: DataType
}.
-export_type([item/1]).
