module Network.Session exposing (Msg, init, update)

import Data.Session exposing (Session)
import Network.Api
import Url exposing (Url)
import Url.Parser
import Url.Parser.Query
import Http exposing (Error)
import Browser.Navigation

type Msg
    = SetError Error
    | GotSession Url (Maybe Session)
    | GotSessionId Url String

route : (x -> Msg) -> Result Error x -> Msg
route success value =
    case value of
        Ok x -> success x
        Err x -> SetError x

init : Url -> Cmd Msg
init url =
    case
        { url | path = "" }
        |> Url.Parser.parse
            (Url.Parser.query
                <| Url.Parser.Query.string "id"
            )
        |> Maybe.andThen identity
    of
        Just id ->
            Network.Api.getSession id
            <| route (GotSession url)
        Nothing ->
            Network.Api.getNewSession
            <| route (GotSessionId url)

update : Browser.Navigation.Key -> Msg -> (Maybe (Result Error Session), Cmd Msg)
update key msg =
    case msg of
        SetError error -> (Just <| Err error, Cmd.none)
        GotSession url Nothing ->
            ( Nothing
            , Network.Api.getNewSession <| route (GotSessionId url)
            )
        GotSession _ (Just session) -> (Just <| Ok session, Cmd.none)
        GotSessionId url id ->
            ( Nothing
            , Cmd.batch
                [ Browser.Navigation.replaceUrl key
                    <| Url.toString { url | query = Just <| "id=" ++ Url.percentEncode id }
                , Network.Api.getSession id <| route (GotSession url)
                ]
            )

