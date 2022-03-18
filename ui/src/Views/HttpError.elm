module Views.HttpError exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Http exposing (Error)

view : Error -> Html msg
view error =
    div [ class "http-error" ]
    <| case error of
        Http.BadUrl url ->
            [ div [] [ text "Bad url: " ]
            , Html.pre [] [ text url ]
            ]
        Http.Timeout ->
            [ div [] [ text "Network timeout. Is the server down?" ]
            ]
        Http.NetworkError ->
            [ div [] [ text "Network error. Try to reconnect to your network." ]
            ]
        Http.BadStatus status ->
            [ div [] [ text <| "Bad status: " ++ String.fromInt status ]
            ]
        Http.BadBody body ->
            [ div [] [ text <| "Invalid response data:" ]
            , Html.pre [ HA.style "white-space" "pre-wrap" ] [ text body ]
            ]
