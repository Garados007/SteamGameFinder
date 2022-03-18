module Data.Steam exposing (..)

import Json.Decode as JD exposing (Decoder)
import Json.Decode.Pipeline exposing (required, optional)
import Time exposing (Posix)
import Dict exposing (Dict)

type alias SteamId = String

type alias AppId = Int

decodeSteamTime : Decoder Posix
decodeSteamTime =
    JD.map
        (Time.millisToPosix << (*) 1000)
    <| JD.int

type alias SteamPlayer =
    { steamid: SteamId
    , communityVisibilityState: Int
    , profileState: Int
    , personaName: String
    , profileUrl: String
    , avatar: String
    , avatarMedium: String
    , avatarFull: String
    , lastLogoff: Posix
    , timeCreated: Posix
    , locCountryCode: String
    -- there are more, but these will be ignored
    }

decodeSteamPlayer : Decoder SteamPlayer
decodeSteamPlayer =
    JD.succeed SteamPlayer
    |> required "steamid" JD.string
    |> required "communityvisibilitystate" JD.int
    |> required "profilestate" JD.int
    |> required "personaname" JD.string
    |> required "profileurl" JD.string
    |> required "avatar" JD.string
    |> required "avatarmedium" JD.string
    |> required "avatarfull" JD.string
    |> required "lastlogoff" decodeSteamTime
    |> required "timecreated" decodeSteamTime
    |> required "loccountrycode" JD.string

type alias SteamGameTime =
    { appid: AppId
    , name: String
    , playtime2Weeks: Int
    , playtimeForever: Int
    , imgIconUrlHash: String
    }

decodeSteamGameTime : Decoder SteamGameTime
decodeSteamGameTime =
    JD.succeed SteamGameTime
    |> required "appid" JD.int
    |> required "name" JD.string
    |> optional "playtime_2weeks" JD.int 0
    |> required "playtime_forever" JD.int
    |> required "img_icon_url" JD.string

type alias SteamUserGameTime =
    { playtime2Weeks: Int
    , playtimeForever: Int
    }

type alias SteamGame =
    { appid: AppId
    , name: String
    , imgIconUrl: String
    , imgBannerUrl: String
    , user: Dict SteamId SteamUserGameTime
    }

toSteamGame : SteamId -> SteamGameTime -> SteamGame
toSteamGame userid gametime =
    { appid = gametime.appid
    , name = gametime.name
    , imgIconUrl = "http://media.steampowered.com/steamcommunity/public/images/apps/"
        ++ String.fromInt gametime.appid ++ "/" ++ gametime.imgIconUrlHash ++ ".jpg"
    , imgBannerUrl = "https://cdn.cloudflare.steamstatic.com/steam/apps/"
        ++ String.fromInt gametime.appid ++ "/header.jpg"
    , user = Dict.singleton userid
        { playtime2Weeks = gametime.playtime2Weeks
        , playtimeForever = gametime.playtimeForever
        }
    }

