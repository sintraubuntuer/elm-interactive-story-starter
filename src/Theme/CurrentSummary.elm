module Theme.CurrentSummary exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Engine


view :
    ( String, { a | name : String } )
    -> List ( String, { a | name : String } )
    -> List ( String, { a | name : String } )
    -> Html (Engine.Msg)
view ( _, currentLocationAttrs ) props characters =
    let
        isEmpty =
            List.isEmpty characters && List.isEmpty props

        interactableView msg ( interactable, attrs ) =
            span
                [ class "CurrentSummary__StoryElement u-selectable"
                , onClick <| msg interactable
                ]
                [ text <| .name attrs ]

        format list =
            let
                interactables =
                    if List.length list > 2 then
                        (List.take (List.length list - 1) list
                            |> List.intersperse (text ", ")
                        )
                            ++ (text " and ")
                            :: (List.drop (List.length list - 1) list)
                    else
                        List.intersperse (text " and ") list
            in
                interactables ++ [ text "." ]

        charactersList =
            if not <| List.isEmpty characters then
                characters
                    |> List.map (interactableView Engine.interactMsg)
                    |> format
                    |> (::) (text "Characters here: ")
                    |> p []
            else
                span [] []

        propsList =
            if not <| List.isEmpty props then
                props
                    |> List.map (interactableView Engine.interactMsg)
                    |> format
                    |> (::) (text "Items here: ")
                    |> p []
            else
                span [] []
    in
        div [ class "CurrentSummary", style [] ]
            <| [ h1 [ class "Current-location" ]
                    [ text <| .name <| currentLocationAttrs ]
               ]
            ++ if isEmpty then
                [ text "Nothing here." ]
               else
                [ charactersList, propsList ]
