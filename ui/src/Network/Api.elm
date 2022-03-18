module Network.Api exposing (..)

import Data.Session exposing (Session)
import Data.Steam exposing (..)
import Http exposing (Error)
import Url
import Json.Decode as JD
import Dict exposing (Dict)

type alias SteamData a = Result (SteamId, String) a 

getSteamUser : SteamId -> (Result Error (SteamData SteamPlayer) -> msg) -> Cmd msg
getSteamUser userid callback =
    Http.get
        { url = "/api/api/user/" ++ Url.percentEncode userid
        , expect = Http.expectJson callback
            <| JD.oneOf
                [ JD.map (Err << Tuple.pair userid) <| JD.field "error" JD.string
                , JD.at [ "response", "players" ]
                    <| JD.map
                        (\list ->
                            case list of
                                [] -> Err (userid, "user not found")
                                l :: _ -> Ok l
                        )
                    <| JD.list decodeSteamPlayer
                ]
        }

getSteamGames : SteamId -> (Result Error (SteamData (Dict AppId SteamGame)) -> msg) -> Cmd msg
getSteamGames userid callback =
    Http.get
        { url = "/api/api/played-games/" ++ Url.percentEncode userid
        , expect = Http.expectJson callback
            <| JD.oneOf
                [ JD.map (Err << Tuple.pair userid) <| JD.field "error" JD.string
                , JD.map Ok
                    <| JD.at [ "response", "games" ]
                    <| JD.map
                        (List.filter (\x -> x.imgIconUrlHash /= "")
                            >> List.map
                                (\x -> (x.appid, toSteamGame userid x))
                            >> Dict.fromList
                        )
                    <| JD.list
                    <| decodeSteamGameTime
                ]
        }

getNewSession : (Result Error String -> msg) -> Cmd msg
getNewSession callback =
    Http.get
        { url = "/api/api/new"
        , expect = Http.expectJson callback
            <| JD.field "id" JD.string
        }

getSession : String -> (Result Error (Maybe Session) -> msg) -> Cmd msg
getSession sessionId callback =
    Http.get
        { url = "/api/api/session/" ++ Url.percentEncode sessionId
        , expect = Http.expectJson callback
            <| JD.oneOf
                [ JD.field "error" 
                    <| JD.andThen
                        (\x ->
                            case x of
                                "not found" -> JD.succeed Nothing
                                _ -> JD.fail <| "Unknown error state: " ++ x
                        )
                    <| JD.string
                , JD.map Just Data.Session.decodeSession
                ]
        }
