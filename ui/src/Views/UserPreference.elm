module Views.UserPreference exposing (..)

import Data exposing (Data)
import Data.Session exposing (Preference)
import Data.Steam exposing (SteamId, AppId, SteamGame)
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Html.Keyed as HK
import Event exposing (Event)
import Triple
import Dict exposing (filter)

type alias PreferenceInfo =
    { undefined: List SteamGame
    , dislike: List SteamGame
    , optional: List SteamGame
    , like: List SteamGame
    }

getPreferenceInfo : SteamId -> Data -> PreferenceInfo
getPreferenceInfo myId data =
    let
        filterBroke : SteamGame -> Bool
        filterBroke game =
            List.foldl
                (\id x -> x && Dict.member id game.user)
                True
            <| Maybe.withDefault []
            <| Maybe.map .broke
            <| data.session

        prefs : Dict AppId Preference
        prefs = data.session
            |> Maybe.map .preferences
            |> Maybe.andThen
                (Dict.get myId)
            |> Maybe.withDefault Dict.empty

        getPref : AppId -> Preference
        getPref id = Dict.get id prefs |> Maybe.withDefault Data.Session.Undefined
        
        insert : Preference -> SteamGame -> PreferenceInfo -> PreferenceInfo
        insert pref game info =
            case pref of
                Data.Session.Undefined ->
                    { info | undefined = game :: info.undefined }
                Data.Session.Dislike ->
                    { info | dislike = game :: info.dislike }
                Data.Session.Optional ->
                    { info | optional = game :: info.optional }
                Data.Session.Like ->
                    { info | like = game :: info.like }

    in Dict.foldl
        (\id game ->
            insert (getPref id) game
        )
        { undefined = [], dislike = [], optional = [], like = [] }
        <| Dict.filter (\_ -> filterBroke)
        <| data.games

getPreference : SteamId -> Preference -> Data -> List SteamGame
getPreference myId pref data =
    let
        filterBroke : SteamGame -> Bool
        filterBroke game =
            List.foldl
                (\id x -> x && Dict.member id game.user)
                True
            <| Maybe.withDefault []
            <| Maybe.map .broke
            <| data.session

        prefs : Dict AppId Preference
        prefs = data.session
            |> Maybe.map .preferences
            |> Maybe.andThen
                (Dict.get myId)
            |> Maybe.withDefault Dict.empty

        getPref : AppId -> Preference
        getPref id = Dict.get id prefs |> Maybe.withDefault Data.Session.Undefined
        

    in Dict.foldl
        (\id game ->
            if getPref id == pref
            then (::) game
            else identity
        )
        []
        <| Dict.filter (\_ -> filterBroke)
        <| data.games

getResultList : SteamId -> Data -> List (Preference, SteamGame)
getResultList myId data =
    let
        filterBroke : SteamGame -> Bool
        filterBroke game =
            List.foldl
                (\id x -> x && Dict.member id game.user)
                True
            <| Maybe.withDefault []
            <| Maybe.map .broke
            <| data.session

        prefs : Dict AppId Preference
        prefs = data.session
            |> Maybe.map .preferences
            |> Maybe.andThen
                (Dict.get myId)
            |> Maybe.withDefault Dict.empty

        getPref : AppId -> Preference
        getPref id = Dict.get id prefs |> Maybe.withDefault Data.Session.Undefined
        

        prefToScore : Preference -> Maybe Int
        prefToScore pref =
            case pref of
                Data.Session.Undefined -> Just 0
                Data.Session.Dislike -> Nothing
                Data.Session.Optional -> Just 1
                Data.Session.Like -> Just 2

        -- get a preference score table
        scores : Dict AppId (Maybe Int) -- higher score is better, Nothing is discard
        scores = data.session
            |> Maybe.map .preferences
            |> Maybe.withDefault Dict.empty
            |> Dict.foldl
                (\_ prefs_ res ->
                    Dict.merge
                        (\k v -> Dict.insert k (prefToScore v))
                        (\k v1 v2 ->
                            Dict.insert k
                            <| Maybe.map2 (+) v2
                            <| prefToScore v1
                        )
                        (Dict.insert)
                        prefs_
                        res
                        Dict.empty
                )
                Dict.empty

        games : List (Int, SteamGame)
        games = data.games
            |> Dict.filter (\_ -> filterBroke)
            |> Dict.foldl
                (\id game ->
                    case Dict.get id scores of
                        Just (Just score) -> (::) (score, game)
                        Just Nothing -> identity
                        Nothing -> (::) (0, game)
                )
                []

        comparer : (Int, SteamGame) -> (Int, SteamGame) -> Order
        comparer (s1,g1) (s2, g2) =
            if s1 == s2
            then compareGame g1 g2
            else compare s2 s1

    in games
        |> List.sortWith comparer
        |> List.map Tuple.second
        |> List.map
            (\x -> (getPref x.appid, x))

type Filter
    = FilterAll
    | FilterPref Preference
    | FilterResult

type alias Model =
    { filter: Filter
    }

type Msg
    = None
    | SendEvent Event
    | SetFilter Filter

init : Model
init =
    { filter = FilterAll
    }

view : Data -> Model -> Html Msg
view data model =
    case data.currentUser of
        Nothing -> text ""
        Just user ->
            div [ class "user-preferences"]
            <| (\list -> viewFilter user data model :: list)
            <| case model.filter of
                FilterAll ->
                    let
                        info : PreferenceInfo
                        info = getPreferenceInfo user data

                    in
                        [ viewGames user data 
                            <| List.map (Tuple.pair Data.Session.Undefined)
                            <| List.sortWith compareGame info.undefined
                        , viewGames user data
                            <| List.map (Tuple.pair Data.Session.Like)
                            <| List.sortWith compareGame info.like
                        , viewGames user data
                            <| List.map (Tuple.pair Data.Session.Optional)
                            <| List.sortWith compareGame info.optional
                        , viewGames user data
                            <| List.map (Tuple.pair Data.Session.Dislike)
                            <| List.sortWith compareGame info.dislike
                        ]
                FilterPref pref ->
                    [ viewGames user data
                        <| List.map (Tuple.pair pref)
                        <| List.sortWith compareGame
                        <| getPreference user pref data 
                    ]
                FilterResult ->
                    [ viewGames user data
                        <| getResultList user data
                    ]

viewFilter : SteamId -> Data -> Model -> Html Msg
viewFilter myId data model =
    div [ class "filter-settings" ]
        [ div [ class "filter-list" ]
        <| (\list ->
                list ++ 
                [  Html.label
                    [ HA.title "This will hide games that you don't own." ]
                    [ Html.input
                        [ HA.type_ "checkbox"
                        , HA.checked
                            <| Maybe.withDefault False
                            <| Maybe.map
                                (.broke >> List.member myId)
                            <| data.session
                        , HE.onCheck <| SendEvent << Event.SetBroke myId
                        ] []
                    , Html.span [] [ text "I am broke" ]
                    ]
                ]
            )
        <| List.map
            (\(cl, tx, fl) ->
                div
                    [ HA.classList
                        [ ("filter", True)
                        , (cl, True)
                        , ("selected", fl == model.filter)
                        ]
                    , HE.onClick <| SetFilter fl
                    ]
                    [ text tx ]
            )
            [ Triple.triple "all" "All" FilterAll
            , Triple.triple "undefined" "Todo" <| FilterPref Data.Session.Undefined
            , Triple.triple "like" "Liked" <| FilterPref Data.Session.Like
            , Triple.triple "optional" "Optional" <| FilterPref Data.Session.Optional
            , Triple.triple "dislike" "Disliked" <| FilterPref Data.Session.Dislike
            , Triple.triple "result" "Result" <| FilterResult
            ]
        ]

playtime : Int -> String
playtime minutes =
    if minutes > 60
    then String.fromInt (minutes // 60) ++ " hour(s) "
        ++ String.fromInt (modBy 60 minutes) ++ " minute(s)"
    else String.fromInt minutes ++ " minute(s)"

compareGame : SteamGame -> SteamGame -> Order
compareGame left right =
    compare (Dict.size left.user |> negate) (Dict.size right.user |> negate)
    |> (\cp ->
            if cp == EQ
            then compare
                (Dict.values left.user |> List.map (.playtimeForever >> negate) |> List.sum)
                (Dict.values right.user |> List.map (.playtimeForever >> negate) |> List.sum)
            else cp
        )

getUserPreference : SteamId -> AppId -> Data -> Preference
getUserPreference user game data =
    data.session
    |> Maybe.andThen
        (.preferences >> Dict.get user)
    |> Maybe.andThen (Dict.get game)
    |> Maybe.withDefault Data.Session.Undefined

viewGames : SteamId -> Data -> List (Preference, SteamGame) -> Html Msg
viewGames myId data list =
    HK.node "div"
        [ class "list" ]
    <| List.map
        (\(preference, game) -> Tuple.pair (String.fromInt game.appid)
            <| div
                [ class "game" ]
                [ Html.a
                    [ HA.target "_blank"
                    , HA.href <| "https://store.steampowered.com/app/"
                        ++ String.fromInt game.appid ++ "/"
                    ]
                    [ Html.img
                        [ class "banner"
                        , HA.src game.imgBannerUrl
                        , HA.attribute "referrerpolicy" "no-referrer"
                        ] []
                    ]
                , div 
                    [ class "title" 
                    , HA.title game.name
                    ]
                    [ Html.img
                        [ class "icon"
                        , HA.src game.imgIconUrl
                        , HA.attribute "referrerpolicy" "no-referrer"
                        ] []
                    , Html.span [] [ text game.name ]
                    ]
                , div [ class "owned" ]
                    <| List.map
                        (\(id, time) ->
                            case Dict.get id data.user of
                                Nothing -> text ""
                                Just user ->
                                    div [ class "owner"
                                        , class
                                            <| case getUserPreference id game.appid data of
                                                Data.Session.Undefined -> ""
                                                Data.Session.Like -> "like"
                                                Data.Session.Optional -> "optional"
                                                Data.Session.Dislike -> "dislike"
                                        , HA.title <| String.concat
                                            [ user.personaName
                                            , "\nPlaytime: "
                                            , playtime time.playtimeForever
                                            , "\n2 weeks: "
                                            , playtime time.playtime2Weeks
                                            ]
                                        ]
                                        [ Html.img
                                            [ HA.src user.avatar 
                                            , HA.attribute "referrerpolicy" "no-referrer"
                                            ] []
                                        ]
                        )
                    <| Dict.toList game.user
                , div [ class "buttons" ]
                    [ div
                        [ HA.classList
                            [ ("button", True)
                            , ("like", True)
                            , ("selected", preference == Data.Session.Like)
                            ]
                        , HE.onClick <| SendEvent
                            <| Event.SetPreference myId game.appid Data.Session.Like
                        ]
                        [ text "Yeah!" ]
                    , div
                        [ HA.classList
                            [ ("button", True)
                            , ("optional", True)
                            , ("selected", preference == Data.Session.Optional)
                            ]
                        , HE.onClick <| SendEvent
                            <| Event.SetPreference myId game.appid Data.Session.Optional
                        ]
                        [ text "Maybe?" ]
                    , div
                        [ HA.classList
                            [ ("button", True)
                            , ("dislike", True)
                            , ("selected", preference == Data.Session.Dislike)
                            ]
                        , HE.onClick <| SendEvent
                            <| Event.SetPreference myId game.appid Data.Session.Dislike
                        ]
                        [ text "Nah!" ]
                    ]
                ]
        )
    <| list

update : Msg -> Data -> Model -> (Model, Cmd Msg, List Event)
update msg data model =
    case msg of
        None -> (model, Cmd.none, [])
        SendEvent event -> (model, Cmd.none, [ event ])
        SetFilter filter -> ({ model | filter = filter }, Cmd.none, [])
