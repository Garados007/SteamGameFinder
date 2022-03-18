module Main exposing (..)

import Browser
import Network.Session
import Browser.Navigation
import Url exposing (Url)
import Data exposing (Data)
import Network
import Network.Messages
import Views.UserInput
import Event exposing (Event)
import Html exposing (Html, text)
import Html.Attributes as HA
import Views.HttpError
import Views.UserSelector
import Views.UserPreference

main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = \_ -> None
        , onUrlRequest = \_ -> None
        }

type alias Model =
    { key: Browser.Navigation.Key
    , data: Data
    , url: Url
    , viewUserInput: Views.UserInput.Model
    , viewUserPref: Views.UserPreference.Model
    }

type Msg
    = None
    | Receive Network.Messages.ReceiveMessage
    | WrapNetworkSession Network.Session.Msg
    | WrapData Data.Msg
    | WrapUserInput Views.UserInput.Msg
    | WrapUserSelector Views.UserSelector.Msg
    | WrapUserPreference Views.UserPreference.Msg

init : () -> Url -> Browser.Navigation.Key -> (Model, Cmd Msg)
init () url key =
    Tuple.pair
        { key = key
        , data = Data.init
        , url = url
        , viewUserInput = Views.UserInput.init
        , viewUserPref = Views.UserPreference.init
        }
    <| Cmd.batch
        [ Cmd.map WrapNetworkSession
            <| Network.Session.init url
        ]

view : Model -> Browser.Document Msg
view model =
    { title = "Steam Game Finder"
    , body =
        [ Html.node "link"
            [ HA.attribute "rel" "stylesheet"
            , HA.attribute "property" "stylesheet"
            , HA.attribute "href" "css/style.css"
            ] []
        , Html.map WrapUserSelector
            <| Views.UserSelector.viewBanner model.data
        , Html.map WrapUserInput
            <| Views.UserInput.view model.data model.viewUserInput
        , Html.map WrapUserSelector
            <| Views.UserSelector.view model.data
        , Html.map WrapUserPreference
            <| Views.UserPreference.view model.data model.viewUserPref
        , case model.data.httpError of
            Nothing -> text ""
            Just error -> Views.HttpError.view error
        -- , Debug.Extra.viewModel model
        ]
    }

apply : Event -> Model -> (Model, Cmd Msg)
apply event model =
    case event of
        Event.AddUser user ->
            Data.addUser user model.data
            |> Tuple.mapBoth
                (\data -> { model | data = data })
                (Cmd.map WrapData)
        Event.SetCurrentUser user ->
            Tuple.pair
                { model
                | data = model.data |> \data ->
                    { data | currentUser = Just user }
                }
                Cmd.none
        Event.SetPreference user game pref ->
            Tuple.pair model
            <| Network.wsSend
            <| Network.Messages.SetPreference user game pref
        Event.SetBroke user broke ->
            Tuple.pair model
            <| Network.wsSend
            <| Network.Messages.SetBroke user broke

applyAll : List Event -> Model -> (Model, Cmd Msg)
applyAll events model =
    List.foldl
        (\event (m, c) ->
            apply event m
            |> Tuple.mapSecond
                (\x -> x :: c)
        )
        (model, [])
        events
    |> Tuple.mapSecond Cmd.batch

applyResult : (m -> Model) -> (c -> Msg) -> (m, Cmd c, List Event) -> (Model, Cmd Msg)
applyResult mapModel mapMsg (model, cmd, events) =
    mapModel model
    |> applyAll events
    |> Tuple.mapSecond
        (\x -> Cmd.batch [ x, Cmd.map mapMsg cmd ])

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        None -> (model, Cmd.none)
        Receive sub ->
            Data.apply sub model.data
            |> Tuple.mapBoth
                (\data -> { model | data = data})
                (Cmd.map WrapData)
        WrapNetworkSession sub ->
            case Network.Session.update model.key sub of
                (Just (Ok session), cmd) ->
                    let
                        (data, dataCmd) = model.data
                            |> \data_ ->
                                { data_
                                | session = Just { session | steamIds = [] }
                                }
                            |> Data.updateUserList session.steamIds
                    in 
                        Tuple.pair
                            { model | data = data }
                        <| Cmd.batch
                            [ Cmd.map WrapNetworkSession cmd
                            , Cmd.map WrapData dataCmd
                            , Network.wsConnect
                                (String.concat
                                    [ case model.url.protocol of
                                        Url.Http -> "http://"
                                        Url.Https -> "https://"
                                    , model.url.host
                                    , case model.url.port_ of
                                        Just p -> ":" ++ String.fromInt p
                                        Nothing -> ""
                                    -- , ":8000"
                                    ]
                                )
                                session.id
                            ]
                (_, cmd) ->
                    (model
                    , Cmd.map WrapNetworkSession cmd
                    )
        WrapData sub ->
            Data.update sub model.data
            |> Tuple.mapBoth
                (\data -> { model | data = data })
                (Cmd.map WrapData)
        WrapUserInput sub ->
            Views.UserInput.update sub model.data model.viewUserInput
            |> applyResult
                (\x -> { model | viewUserInput = x })
                WrapUserInput
        WrapUserSelector sub ->
            Views.UserSelector.update sub
            |> applyResult
                (always model)
                WrapUserSelector
        WrapUserPreference sub ->
            Views.UserPreference.update sub model.data model.viewUserPref
            |> applyResult
                (\x -> { model | viewUserPref = x })
                WrapUserPreference

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Network.wsReceive
            <| \result ->
                case result of
                    Ok x -> Receive x
                    Err _ -> None
        , Network.wsClose <| always None
        ]
