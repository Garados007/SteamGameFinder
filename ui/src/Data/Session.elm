module Data.Session exposing (..)

import Dict exposing (Dict)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)
import Data.Steam exposing (SteamId, AppId)

type alias Session =
    { id: String
    , steamIds: List SteamId
    , broke: List SteamId
    , preferences: Dict SteamId (Dict AppId Preference)
    }

decodeSession : Decoder Session
decodeSession =
    JD.map4 Session
        (JD.field "id" JD.string)
        (JD.field "steamids" <| JD.list JD.string)
        (JD.field "broke" <| JD.list JD.string)
        (JD.field "preferences"
            <| JD.dict
            <| JD.andThen
                (\list ->
                    case
                        List.foldl
                            (\(key, value) ->
                                Maybe.map2
                                    (\k d -> Dict.insert k value d)
                                <| String.toInt key
                            )
                            (Just Dict.empty)
                            list
                    of
                        Nothing -> JD.fail "invalid appId format"
                        Just d -> JD.succeed d
                )
            <| JD.keyValuePairs decodePreference
        )

type Preference
    = Undefined
    | Dislike
    | Optional
    | Like

decodePreference : Decoder Preference
decodePreference =
    JD.andThen
        (\value ->
            case value of
                "Undefined" -> JD.succeed Undefined
                "Dislike" -> JD.succeed Dislike
                "Optional" -> JD.succeed Optional
                "Like" -> JD.succeed Like
                _ -> JD.fail <| "Unknown preference: " ++ value
        )
    <| JD.string

encodePreference : Preference -> Value
encodePreference value =
    case value of
        Undefined -> JE.string "Undefined"
        Dislike -> JE.string "Dislike"
        Optional -> JE.string "Optional"
        Like -> JE.string "Like"
