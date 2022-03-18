module Data exposing (..)

-- the global data state

import Data.Session exposing (Session)
import Data.Steam exposing (AppId, SteamGame, SteamId, SteamPlayer)
import Dict exposing (Dict)
import Http exposing (Error)
import Network.Api
import Network
import Network.Messages

type alias Data =
    { session: Maybe Session
    , games: Dict AppId SteamGame
    , user: Dict SteamId SteamPlayer
    , currentUser: Maybe SteamId
    , invalidUser: Dict SteamId String
    , httpError: Maybe Error
    }

init : Data
init =
    { session = Nothing
    , games = Dict.empty
    , user = Dict.empty
    , currentUser = Nothing
    , invalidUser = Dict.empty
    , httpError = Nothing
    }

route : (x -> Msg) -> Result Error x -> Msg
route success value =
    case value of
        Ok x -> success x
        Err x -> SetError x

route2 : (a -> c) -> (b -> c) -> Result a b -> c
route2 onErr onOk result =
    case result of
        Ok x -> onOk x
        Err x -> onErr x

type Msg
    = SetError Error
    | SetSteamUserErr (SteamId, String)
    | SetSteamUser SteamPlayer
    | SetSteamGames (Dict AppId SteamGame)
    
update : Msg -> Data -> (Data, Cmd Msg)
update msg data =
    case msg of
        SetError error ->
            Tuple.pair
                { data | httpError = Just error }
                Cmd.none
        SetSteamUserErr (id, error) ->
            Tuple.pair
                { data | invalidUser = Dict.insert id error data.invalidUser }
                Cmd.none
        SetSteamUser user ->
            Tuple.pair
                { data | user = Dict.insert user.steamid user data.user }
            <|  if Dict.member user.steamid data.user
                then Cmd.none
                else Network.Api.getSteamGames user.steamid
                    <| route
                    <| route2 SetSteamUserErr SetSteamGames
        SetSteamGames games ->
            Tuple.pair
                { data
                | games = Dict.merge
                    Dict.insert
                    (\key old new ->
                        Dict.insert key
                            { old
                            | user = Dict.union new.user old.user
                            }
                    )
                    Dict.insert
                    data.games
                    games
                    Dict.empty                    
                }
                Cmd.none

addUser : SteamId -> Data -> (Data, Cmd Msg)
addUser user data =
    if case data.session of
        Nothing -> True
        Just session -> List.member user session.steamIds
    then (data, Cmd.none)
    else Tuple.pair
        { data
        | session = Maybe.map
            (\session ->
                { session | steamIds = session.steamIds ++ [ user ] }
            )
            data.session
        }
        <| Cmd.batch
            [ Network.Api.getSteamUser user
                <| route <| route2 SetSteamUserErr SetSteamUser
            , Network.wsSend
                <| Network.Messages.ChangeUser
                <| case data.session of
                    Nothing -> []
                    Just session -> session.steamIds ++ [ user ]
            ]

removeUser : SteamId -> Data -> (Data, Cmd Msg)
removeUser user data =
    if case data.session of
        Nothing -> True
        Just session -> not <| List.member user session.steamIds
    then (data, Cmd.none)
    else Tuple.pair
        { data
        | session = Maybe.map
            (\session ->
                { session
                | steamIds = List.filter ((/=) user) session.steamIds
                }
            )
            data.session
        }
        <| Cmd.batch
            [ Network.wsSend
                <| Network.Messages.ChangeUser
                <| case data.session of
                    Nothing -> []
                    Just session ->
                        List.filter ((/=) user) session.steamIds
            ]

updateUserList : List SteamId -> Data -> (Data, Cmd Msg)
updateUserList users data =
    let
        oldUserList : List SteamId
        oldUserList = data.session
            |> Maybe.map .steamIds
            |> Maybe.withDefault []

        added : List SteamId
        added = List.filter (\x -> not <| List.member x oldUserList) users

    in Tuple.pair
        { data
        | session = Maybe.map
            (\session -> { session | steamIds = users })
            data.session
        }
        <| Cmd.batch
        <| List.map
            (\user ->
                Network.Api.getSteamUser user
                    <| route <| route2 SetSteamUserErr SetSteamUser
            )
        <| added

apply : Network.Messages.ReceiveMessage -> Data -> (Data, Cmd Msg)
apply msg data =
    case msg of
        Network.Messages.SendInfo session ->
            updateUserList session.steamIds
                { data
                | session = Just
                    { session
                    | steamIds = Maybe.withDefault []
                        <| Maybe.map .steamIds data.session
                    }
                }
        Network.Messages.UpdatedUser users ->
            updateUserList users data
        Network.Messages.UpdatePreference user game preference ->
            Tuple.pair
                { data
                | session = Maybe.map
                    (\session ->
                        { session 
                        | preferences = Dict.update user
                            (Maybe.withDefault Dict.empty
                                >> Dict.insert game preference
                                >> Just
                            )
                            session.preferences
                        }
                    )
                    data.session
                }
                Cmd.none
        Network.Messages.UpdateBroke user broke ->
            Tuple.pair
                { data
                | session = Maybe.map
                    (\session ->
                        { session
                        | broke = session.broke
                            |> List.filter ((/=) user)
                            |>  ( if broke
                                    then (::) user
                                    else identity
                                )
                        }
                    )
                    data.session
                }
                Cmd.none
