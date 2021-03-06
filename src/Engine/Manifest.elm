module Engine.Manifest exposing
    ( attrValueIsEqualTo
    , character
    , characterIsInLocation
    , choiceHasAlreadyBeenMade
    , chosenOptionIsEqualTo
    , countWritableItemsInLocation
    , counterExists
    , counterGreaterThenOrEqualTo
    , counterLessThen
    , getAttributeByIdAndInteractableId
    , getCharactersInLocation
    , getInteractableAttribute
    , getItemWrittenContent
    , getItemsInCharacterInventory
    , getItemsInLocation
    , getItemsInLocationIncludeWrittenContent
    , getLocations
    , init
    , isCharacter
    , isItem
    , isLocation
    , isWritable
    , item
    , itemIsCorrectlyAnswered
    , itemIsInAnyLocationOrAnyCharacterInventory
    , itemIsInAnyLocationOrCharacterInventory
    , itemIsInCharacterInventory
    , itemIsInLocation
    , itemIsIncorrectlyAnswered
    , itemIsNotAnswered
    , itemIsNotCorrectlyAnswered
    , itemIsNotInLocation
    , itemIsOffScreen
    , location
    , noChosenOptionYet
    , update
    )

import Dict exposing (Dict)
import Regex
import Types exposing (..)



{- This is code from the Elm Narrative Engine https://github.com/jschomay/elm-narrative-engine/tree/3.0.0 To which i added/modified some parts to convert it to a Game-Narrative Engine
   so that players are able to answer questions , options , etc ...
-}


init :
    { items : List ( String, Dict String Types.AttrTypes )
    , locations : List ( String, Dict String Types.AttrTypes )
    , characters : List ( String, Dict String Types.AttrTypes )
    }
    -> Manifest
init { items, locations, characters } =
    let
        insertInterFn interactableConstructor ( interId, interInfo ) acc =
            Dict.insert interId (interactableConstructor ( interId, interInfo )) acc

        foldInterFn interactableConstructor interactableList acc =
            List.foldr (\( interId, interInfo ) -> insertInterFn interactableConstructor ( interId, interInfo )) acc interactableList
    in
    Dict.empty
        |> foldInterFn item items
        |> foldInterFn location locations
        |> foldInterFn character characters


item : ( String, Dict String Types.AttrTypes ) -> Interactable
item ( itemId, dictItemInfo ) =
    let
        --ItemData  interactableId fixed  itemPlacement  isWritable  writtenContent  attributes  interactionErrors interactionWarnings
        itemData =
            ItemData itemId False ItemOffScreen False Nothing dictItemInfo [] [] []
    in
    Item itemData


location : ( String, Dict String Types.AttrTypes ) -> Interactable
location ( locationId, dictLocationInfo ) =
    let
        --  LocationData interactableId  shown    attributes  interactionErrors interactionWarnings
        locationData =
            LocationData locationId False dictLocationInfo [] [] []
    in
    Location locationData


character : ( String, Dict String Types.AttrTypes ) -> Interactable
character ( characterId, dictCharacterInfo ) =
    let
        --  CharacterData  interactableId  characterPlacement  attributes   interactionErrors  interactionWarnings
        characterData =
            CharacterData characterId CharacterOffScreen dictCharacterInfo [] [] []
    in
    Character characterData


getItemsInCharacterInventory : String -> Manifest -> List String
getItemsInCharacterInventory charId manifest =
    let
        isInInventory ( id, interactable ) =
            case interactable of
                Item idata ->
                    if idata.itemPlacement == ItemInCharacterInventory charId then
                        Just id

                    else
                        Nothing

                _ ->
                    Nothing
    in
    Dict.toList manifest
        |> List.filterMap isInInventory


getLocations : Manifest -> List String
getLocations manifest =
    let
        isShownLocation ( id, interactable ) =
            case interactable of
                Location locData ->
                    if locData.shown then
                        Just id

                    else
                        Nothing

                _ ->
                    Nothing
    in
    Dict.toList manifest
        |> List.filterMap isShownLocation


getCharactersInLocation : String -> Manifest -> List String
getCharactersInLocation locationId manifest =
    let
        isInLocation locId ( id, interactable ) =
            case interactable of
                Character cdata ->
                    case cdata.characterPlacement of
                        CharacterInLocation alocation ->
                            if alocation == locId then
                                Just id

                            else
                                Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
    Dict.toList manifest
        |> List.filterMap (isInLocation locationId)


getItemsInLocation : String -> Manifest -> List String
getItemsInLocation locationId manifest =
    let
        isInLocation locationIdArg ( id, interactable ) =
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInLocation locId ->
                            if locId == locationIdArg then
                                Just id

                            else
                                Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
    Dict.toList manifest
        |> List.filterMap (isInLocation locationId)


countWritableItemsInLocation : String -> Manifest -> Int
countWritableItemsInLocation locationId manifest =
    let
        isInLocationAndWritable locationIdArg ( id, interactable ) =
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInLocation locId ->
                            if locId == locationIdArg && idata.isWritable then
                                Just id

                            else
                                Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
    Dict.toList manifest
        |> List.filterMap (isInLocationAndWritable locationId)
        |> List.length


isWritable : String -> Manifest -> Bool
isWritable interactableId manifest =
    Dict.get interactableId manifest
        |> (\mbinteractable ->
                case mbinteractable of
                    Just (Item idata) ->
                        idata.isWritable

                    _ ->
                        False
           )


getItemsInLocationIncludeWrittenContent : String -> Manifest -> List ( String, Maybe String )
getItemsInLocationIncludeWrittenContent locationId manifest =
    let
        isInLocation locationIdArg ( id, interactable ) =
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInLocation locId ->
                            if locId == locationIdArg then
                                Just ( id, idata.writtenContent )

                            else
                                Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
    Dict.toList manifest
        |> List.filterMap (isInLocation locationId)


isItem : String -> Manifest -> Bool
isItem id manifest =
    Dict.get id manifest
        |> (\interactable ->
                case interactable of
                    Just (Item idata) ->
                        True

                    _ ->
                        False
           )


isLocation : String -> Manifest -> Bool
isLocation id manifest =
    Dict.get id manifest
        |> (\interactable ->
                case interactable of
                    Just (Location _) ->
                        True

                    _ ->
                        False
           )


isCharacter : String -> Manifest -> Bool
isCharacter id manifest =
    Dict.get id manifest
        |> (\interactable ->
                case interactable of
                    Just (Character cdata) ->
                        True

                    _ ->
                        False
           )


noChosenOptionYet : String -> Manifest -> Bool
noChosenOptionYet interactableId manifest =
    Dict.get interactableId manifest
        |> (\interactable ->
                case interactable of
                    Just (Item idata) ->
                        if
                            Dict.get "answerOptionsList" idata.attributes
                                /= Nothing
                                && Dict.get "chosenOption" idata.attributes
                                == Nothing
                        then
                            True

                        else
                            False

                    _ ->
                        False
           )


choiceHasAlreadyBeenMade : String -> Manifest -> Bool
choiceHasAlreadyBeenMade interactableId manifest =
    not <| noChosenOptionYet interactableId manifest


chosenOptionIsEqualTo : String -> Maybe String -> Bool
chosenOptionIsEqualTo valueToMatch mbInputText =
    if Just valueToMatch == mbInputText then
        True

    else
        False


checkForNonExistantInteractableId : String -> Manifest -> List String -> List String
checkForNonExistantInteractableId interactableId manifest linteractionincidents =
    case Dict.get interactableId manifest of
        Nothing ->
            List.append linteractionincidents [ "Interactable with InteractableId : " ++ interactableId ++ " doesn't exist !" ]

        Just interactable ->
            linteractionincidents


checkForNonExistantLocationId : String -> Manifest -> List String -> List String
checkForNonExistantLocationId locationId manifest linteractionincidents =
    case Dict.get locationId manifest of
        Nothing ->
            List.append linteractionincidents [ "Problem on interaction with Location . LocationId : " ++ locationId ++ " doesn't exist !" ]

        Just interactable ->
            linteractionincidents


manifestUpdate : String -> (Maybe Interactable -> Maybe Interactable) -> ( Manifest, List String ) -> ( Manifest, List String )
manifestUpdate interactbaleId updateFuncMbToMb ( manifest, linteractionincidents ) =
    let
        newManifest =
            Dict.update interactbaleId updateFuncMbToMb manifest

        newInteractionIncidents =
            linteractionincidents
                |> checkForNonExistantInteractableId interactbaleId newManifest

        -- add the interactionErrors and the interactionWarnings info from the interactable
        incidentswithInterErrors =
            getInteractionErrors interactbaleId newManifest
                |> List.map (\x -> "Interaction Error : " ++ x)
                |> List.append newInteractionIncidents

        incidentswithInterErrorsAndWarnings =
            getInteractionWarnings interactbaleId newManifest
                |> List.map (\x -> "Interaction Warning : " ++ x)
                |> List.append incidentswithInterErrors

        -- clear the interactionErrors and interactionWarnings on the interactable
        newManifestUpdated =
            newManifest
                |> Dict.update interactbaleId (clearInteractionIncidents "warning")
                |> Dict.update interactbaleId (clearInteractionIncidents "error")
    in
    ( newManifestUpdated, incidentswithInterErrorsAndWarnings )


manifestUpdateWithLocCheck : String -> String -> (Maybe Interactable -> Maybe Interactable) -> ( Manifest, List String ) -> ( Manifest, List String )
manifestUpdateWithLocCheck interactbaleId locationId updateFuncMbToMb ( manifest, linteractionincidents ) =
    let
        newManifest =
            Dict.update interactbaleId updateFuncMbToMb manifest

        newInteractionIncidents =
            linteractionincidents
                |> checkForNonExistantInteractableId interactbaleId newManifest
                |> checkForNonExistantLocationId locationId newManifest

        -- add the interactionErrors and the interactionWarnings info from the interactable
        incidentswithInterErrors =
            getInteractionErrors interactbaleId newManifest
                |> List.map (\x -> "Interaction Error on lock check : " ++ x)
                |> List.append newInteractionIncidents

        incidentswithInterErrorsAndWarnings =
            getInteractionWarnings interactbaleId newManifest
                |> List.map (\x -> "Interaction Warning on lock check : " ++ x)
                |> List.append incidentswithInterErrors

        -- clear the interactionErrors and interactionWarnings on the interactable
        newManifestUpdated =
            newManifest
                |> Dict.update interactbaleId (clearInteractionIncidents "warning")
                |> Dict.update interactbaleId (clearInteractionIncidents "error")
    in
    ( newManifestUpdated, incidentswithInterErrorsAndWarnings )


update : ChangeWorldCommand -> ( Types.Story, List String ) -> ( Types.Story, List String )
update change ( storyRecord, linteractionincidents ) =
    case change of
        NoChange ->
            ( storyRecord, linteractionincidents )

        MoveTo locationId ->
            ( { storyRecord | currentLocation = locationId }, linteractionincidents )

        AddLocation id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id addLocation ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        RemoveLocation id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id removeLocation ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MoveItemToCharacterInventory charId id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id (moveItemToCharacterInventory charId storyRecord.manifest) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MoveItemToLocation itemId locationId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate itemId (moveItemToLocation locationId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MoveItemToLocationFixed itemId locationId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdateWithLocCheck itemId locationId (moveItemToLocationFixed locationId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MoveItemOffScreen id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id moveItemOffScreen ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MoveCharacterToLocation characterId locationId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdateWithLocCheck characterId locationId (moveCharacterToLocation locationId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MoveCharacterOffScreen id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id moveCharacterOffScreen ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        WriteTextToItem theLgTextDict id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id (writeTextToItem theLgTextDict) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        WriteForceTextToItemFromGivenItemAttr attrid intcId id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id (writeForceTextToItemFromOtherInteractableAttrib attrid intcId storyRecord.manifest) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        WriteGpsLocInfoToItem theInfoStr extraInfo id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id (writeGpsLocInfoToItem theInfoStr) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        ClearWrittenText id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id clearWrittenText ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        CheckIfAnswerCorrect theText playerAnswer cAnswerData interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (checkIfAnswerCorrect theText playerAnswer cAnswerData storyRecord.manifest) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )
                |> processNewChangeWorldCommands interactableId

        CheckAndActIfChosenOptionIs playerChoice lcOptionData interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (checkAndActIfChosenOptionIs playerChoice lcOptionData interactableId storyRecord.manifest) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )
                |> processNewChangeWorldCommands interactableId

        --ProcessChosenOptionEqualTo cOptionData id ->
        --    manifestUpdate id (processChosenOptionEqualTo cOptionData manifest) ( manifest, linteractionincidents )
        ResetOption interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId resetOption ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        CreateAMultiChoice dslss id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id (createAmultiChoice dslss) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        RemoveMultiChoiceOptions id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id removeMultiChoiceOptions ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        CreateCounterIfNotExists counterId interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (createCounterIfNotExists counterId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        IncreaseCounter counterId interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (increaseCounter counterId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        CreateAttributeIfNotExists attrValue attrId interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (createAttributeIfNotExists attrValue attrId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        SetAttributeValue attrValue attrId interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (setAttributeValue attrValue attrId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        CreateAttributeIfNotExistsAndOrSetValue attrValue attrId interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (createAttributeIfNotExistsAndOrSetValue attrValue attrId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        CreateOrSetAttributeValueFromOtherInterAttr attrId otherInterAtrrId otherInterId interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (createOrSetAttributeValueFromOtherInterAttr attrId otherInterAtrrId otherInterId storyRecord.manifest) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        RemoveAttributeIfExists attrId interactableId ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate interactableId (removeAttributeIfExists attrId) ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MakeItemWritable id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id makeItemWritable ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MakeItemUnwritable id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id makeItemUnwritable ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        RemoveChooseOptions id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id removeChooseOptions ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        MakeItUnanswerable id ->
            let
                ( newManifest, newIncidents ) =
                    manifestUpdate id makeItUnanswerable ( storyRecord.manifest, linteractionincidents )
            in
            ( { storyRecord | manifest = newManifest }, newIncidents )

        ExecuteCustomFunc func extraInfo interactableId ->
            let
                lChangeWorldCommands =
                    func extraInfo storyRecord.manifest
            in
            List.foldl (\chg tup -> update chg tup) ( storyRecord, linteractionincidents ) lChangeWorldCommands

        LoadScene sceneName ->
            ( { storyRecord | currentScene = sceneName }, linteractionincidents )

        SetChoiceLanguages dictLgs ->
            ( { storyRecord | choiceLanguages = dictLgs }, linteractionincidents )

        AddChoiceLanguage lgId lgName ->
            ( { storyRecord | choiceLanguages = Dict.insert lgId lgName storyRecord.choiceLanguages }, linteractionincidents )

        EndStory endingtype ending ->
            ( { storyRecord | theEnd = Just (TheEnd endingtype ending) }, linteractionincidents )


createAmultiChoice : Dict String (List ( String, String )) -> Maybe Interactable -> Maybe Interactable
createAmultiChoice dslss mbInteractable =
    createAttributeIfNotExistsAndOrSetValue (ADictStringLSS dslss) "answerOptionsList" mbInteractable
        |> createAttributeIfNotExistsAndOrSetValue (ADictStringLSS dslss) "answerOptionsListBackup"
        |> removeAttributeIfExists "chosenOption"


reactivateMultiChoiceFromBackup : Maybe Interactable -> Maybe Interactable
reactivateMultiChoiceFromBackup mbInteractable =
    let
        mbAnsOptList =
            getInteractableAttribute "answerOptionsListBackup" mbInteractable
    in
    case mbAnsOptList of
        Just ansOptList ->
            createAttributeIfNotExistsAndOrSetValue ansOptList "answerOptionsList" mbInteractable
                |> removeAttributeIfExists "chosenOption"

        Nothing ->
            mbInteractable


removeMultiChoiceOptions : Maybe Interactable -> Maybe Interactable
removeMultiChoiceOptions mbInteractable =
    removeAttributeIfExists "answerOptionsList" mbInteractable


processNewChangeWorldCommands : String -> ( Types.Story, List String ) -> ( Types.Story, List String )
processNewChangeWorldCommands interactableId ( storyRecord, linteractionincidents ) =
    case Dict.get interactableId storyRecord.manifest of
        Just (Item idata) ->
            let
                ( newStory, nInteractionIncidents ) =
                    List.foldl (\chg tup -> update chg tup) ( storyRecord, linteractionincidents ) idata.newCWCmds

                ( updatedManifest, newInteractionIncidents ) =
                    manifestUpdate interactableId clearNextChangeWorldCommandsToBeExecuted ( newStory.manifest, nInteractionIncidents )
            in
            ( { newStory | manifest = updatedManifest }, newInteractionIncidents )

        Just (Character cdata) ->
            let
                ( newStory, nInteractionIncidents ) =
                    List.foldl (\chg tup -> update chg tup) ( storyRecord, linteractionincidents ) cdata.newCWCmds

                ( updatedManifest, newInteractionIncidents ) =
                    manifestUpdate interactableId clearNextChangeWorldCommandsToBeExecuted ( newStory.manifest, nInteractionIncidents )
            in
            ( { newStory | manifest = updatedManifest }, newInteractionIncidents )

        Just (Location ldata) ->
            let
                ( newStory, nInteractionIncidents ) =
                    List.foldl (\chg tup -> update chg tup) ( storyRecord, linteractionincidents ) ldata.newCWCmds

                ( updatedManifest, newInteractionIncidents ) =
                    manifestUpdate interactableId clearNextChangeWorldCommandsToBeExecuted ( newStory.manifest, nInteractionIncidents )
            in
            ( { newStory | manifest = updatedManifest }, newInteractionIncidents )

        Nothing ->
            ( storyRecord, linteractionincidents )


getInteractionErrors : String -> Manifest -> List String
getInteractionErrors interactableId manifest =
    case Dict.get interactableId manifest of
        Just (Item idata) ->
            idata.interactionErrors

        Just (Character cdata) ->
            cdata.interactionErrors

        Just (Location ldata) ->
            ldata.interactionErrors

        Nothing ->
            []


getInteractionWarnings : String -> Manifest -> List String
getInteractionWarnings interactableId manifest =
    case Dict.get interactableId manifest of
        Just (Item idata) ->
            idata.interactionWarnings

        Just (Character cdata) ->
            cdata.interactionWarnings

        Just (Location ldata) ->
            ldata.interactionWarnings

        Nothing ->
            []


createCounterIfNotExists : String -> Maybe Interactable -> Maybe Interactable
createCounterIfNotExists counterId mbinteractable =
    let
        getNewDataRecord : String -> { a | attributes : Dict String AttrTypes } -> { a | attributes : Dict String AttrTypes }
        getNewDataRecord thecounterId dataRecord =
            let
                counterStrID =
                    "counter_" ++ thecounterId

                newAttributes =
                    case Dict.get counterStrID dataRecord.attributes of
                        Nothing ->
                            Dict.insert counterStrID (AnInt 0) dataRecord.attributes

                        Just c ->
                            dataRecord.attributes

                newDataRecord =
                    { dataRecord | attributes = newAttributes }
            in
            newDataRecord
    in
    case mbinteractable of
        Just (Item idata) ->
            Just (Item <| getNewDataRecord counterId idata)

        Just (Character cdata) ->
            Just (Character <| getNewDataRecord counterId cdata)

        Just (Location ldata) ->
            Just (Location <| getNewDataRecord counterId ldata)

        Nothing ->
            Nothing


increaseCounter : String -> Maybe Interactable -> Maybe Interactable
increaseCounter counterId mbinteractable =
    let
        getNewDataRecord : String -> { a | attributes : Dict String AttrTypes } -> { a | attributes : Dict String AttrTypes }
        getNewDataRecord thecounterId dataRecord =
            let
                counterStrID =
                    "counter_" ++ thecounterId

                newAttributes =
                    case Dict.get counterStrID dataRecord.attributes of
                        Nothing ->
                            dataRecord.attributes

                        Just attrval ->
                            case attrval of
                                AnInt val ->
                                    Dict.update counterStrID (\_ -> Just (AnInt (val + 1))) dataRecord.attributes

                                _ ->
                                    dataRecord.attributes

                newDataRecord =
                    { dataRecord | attributes = newAttributes }
            in
            newDataRecord
    in
    case mbinteractable of
        Just (Item idata) ->
            Just (Item <| getNewDataRecord counterId idata)

        Just (Character cdata) ->
            Just (Character <| getNewDataRecord counterId cdata)

        Just (Location ldata) ->
            Just (Location <| getNewDataRecord counterId ldata)

        Nothing ->
            Nothing


createAttributeIfNotExists : AttrTypes -> String -> Maybe Interactable -> Maybe Interactable
createAttributeIfNotExists initialVal attrId mbinteractable =
    let
        getNewDataRecord : AttrTypes -> String -> { a | attributes : Dict String AttrTypes } -> { a | attributes : Dict String AttrTypes }
        getNewDataRecord theInitialVal theAttrId dataRecord =
            let
                newAttributes =
                    case Dict.get theAttrId dataRecord.attributes of
                        Nothing ->
                            Dict.insert theAttrId theInitialVal dataRecord.attributes

                        Just c ->
                            dataRecord.attributes

                newDataRecord =
                    { dataRecord | attributes = newAttributes }
            in
            newDataRecord
    in
    case mbinteractable of
        Just (Item idata) ->
            Just (Item <| getNewDataRecord initialVal attrId idata)

        Just (Character cdata) ->
            Just (Character <| getNewDataRecord initialVal attrId cdata)

        Just (Location ldata) ->
            Just (Location <| getNewDataRecord initialVal attrId ldata)

        Nothing ->
            Nothing


writeInteractionIncident : String -> String -> Maybe Interactable -> Maybe Interactable
writeInteractionIncident incidentType incidentStr mbInteractable =
    let
        writeHelper : String -> String -> { a | interactableId : String, interactionErrors : List String, interactionWarnings : List String } -> { a | interactableId : String, interactionErrors : List String, interactionWarnings : List String }
        writeHelper theIncidentType theIncidentStr dataRecord =
            let
                descriptionStr : String
                descriptionStr =
                    theIncidentStr ++ "InteractableId : " ++ dataRecord.interactableId
            in
            if theIncidentType == "warning" then
                { dataRecord | interactionWarnings = descriptionStr :: dataRecord.interactionWarnings }

            else
                { dataRecord | interactionErrors = descriptionStr :: dataRecord.interactionErrors }
    in
    case mbInteractable of
        Just (Item idata) ->
            Just (Item <| writeHelper incidentType incidentStr idata)

        Just (Character cdata) ->
            Just (Character <| writeHelper incidentType incidentStr cdata)

        Just (Location ldata) ->
            Just (Location <| writeHelper incidentType incidentStr ldata)

        Nothing ->
            Nothing


clearInteractionIncidents : String -> Maybe Interactable -> Maybe Interactable
clearInteractionIncidents incidentType mbInteractable =
    let
        clearHelper : String -> { a | interactableId : String, interactionErrors : List String, interactionWarnings : List String } -> { a | interactableId : String, interactionErrors : List String, interactionWarnings : List String }
        clearHelper theIncidentType dataRecord =
            if theIncidentType == "warning" then
                { dataRecord | interactionWarnings = [] }

            else
                { dataRecord | interactionErrors = [] }
    in
    case mbInteractable of
        Just (Item idata) ->
            Just (Item <| clearHelper incidentType idata)

        Just (Character cdata) ->
            Just (Character <| clearHelper incidentType cdata)

        Just (Location ldata) ->
            Just (Location <| clearHelper incidentType ldata)

        Nothing ->
            Nothing


addLocation : Maybe Interactable -> Maybe Interactable
addLocation mbInteractable =
    case mbInteractable of
        Just (Location ldata) ->
            let
                newldata =
                    { ldata | shown = True }
            in
            Just (Location newldata)

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use addLocation function with an interactable that is not a Location ! "


removeLocation : Maybe Interactable -> Maybe Interactable
removeLocation mbInteractable =
    case mbInteractable of
        Just (Location ldata) ->
            let
                newldata =
                    { ldata | shown = False }
            in
            Just (Location newldata)

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use removeLocation function with an interactable that is not a Location ! "


moveItemToCharacterInventory : String -> Manifest -> Maybe Interactable -> Maybe Interactable
moveItemToCharacterInventory charId manifest mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            if not idata.fixed then
                case Dict.get charId manifest of
                    Just acharacter ->
                        Just (Item { idata | itemPlacement = ItemInCharacterInventory charId })

                    Nothing ->
                        mbInteractable
                            |> writeInteractionIncident "error" "Trying to use moveItemToCharacterInventory function with a character that doesn't exist ! "

            else
                mbInteractable
                    |> writeInteractionIncident "warning" "Trying to use moveItemToCharacterInventory function with an interactable that is an Item fixed to a Location . Can't be moved ! "

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveItemToCharacterInventory function with an interactable that is not an Item ! "


moveItemOffScreen : Maybe Interactable -> Maybe Interactable
moveItemOffScreen mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | fixed = False, itemPlacement = ItemOffScreen })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveItemOffScreen function with an interactable that is not an Item ! "


moveItemToLocationFixed : String -> Maybe Interactable -> Maybe Interactable
moveItemToLocationFixed locationId mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | fixed = True, itemPlacement = ItemInLocation locationId })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveItemToLocationFixed function with an interactable that is not an Item ! "


moveItemToLocation : String -> Maybe Interactable -> Maybe Interactable
moveItemToLocation locationId mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            -- still have to Check if location exists
            Just (Item { idata | fixed = False, itemPlacement = ItemInLocation locationId })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveItemToLocation function with an interactable that is not an Item ! "


makeItemWritable : Maybe Interactable -> Maybe Interactable
makeItemWritable mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | isWritable = True })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use makeItemWritable function with an interactable that is not an Item ! "


makeItemUnwritable : Maybe Interactable -> Maybe Interactable
makeItemUnwritable mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | isWritable = False })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use makeItemUnwritable function with an interactable that is not an Item ! "


{-| if the interactable has some options/answers associated with it from which the user can chose
this function will remove those options ( buttons ) by removing the attribute
responsible for their display on the storyline
-}
removeChooseOptions : Maybe Interactable -> Maybe Interactable
removeChooseOptions mbinteractable =
    removeAttributeIfExists "answerOptionsList" mbinteractable


{-| makes simultaneously the item unwritable ( answerBox is removed if there was one )
and also removes choice options/buttons if they were available that might allow a player to answer something
-}
makeItUnanswerable : Maybe Interactable -> Maybe Interactable
makeItUnanswerable mbinteractable =
    makeItemUnwritable mbinteractable
        |> removeChooseOptions


{-| writes text to the writtenContent of the Item if the item isWritable
-}
writeTextToItem : String -> Maybe Interactable -> Maybe Interactable
writeTextToItem theText mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            if idata.isWritable then
                Just (Item { idata | writtenContent = Just theText })

            else
                mbinteractable
                    |> writeInteractionIncident "warning" "Trying to use writeTextToItem function with an interactable that is a notWritable Item ! "

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use writeTextToItem function with an interactable that is not an Item ! "


writeForceTextToItemFromOtherInteractableAttrib : String -> String -> Manifest -> Maybe Interactable -> Maybe Interactable
writeForceTextToItemFromOtherInteractableAttrib attrid intcId manifest mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            let
                theAttrVal =
                    -- still have to check if other InteractableId exists
                    getInteractableAttribute attrid (Dict.get intcId manifest)

                theText =
                    case theAttrVal of
                        Just (Abool bval) ->
                            if bval then
                                "True"

                            else
                                "False"

                        Just (Astring s) ->
                            s

                        Just (AnInt i) ->
                            String.fromInt i

                        _ ->
                            ""
            in
            Just (Item { idata | writtenContent = Just theText })

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use writeForceTextToItemFromOtherInteractableAttrib function with an interactable that is not an Item ! "


{-| writes info to the item regardless of whether the item is writable or not.
we don't want to make the item writable because an input textbox would be displayed to the user
, but we still want to write this info to the item , so ...
-}
writeGpsLocInfoToItem : String -> Maybe Interactable -> Maybe Interactable
writeGpsLocInfoToItem infoText mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | writtenContent = Just infoText })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use writeGpsLocInfoToItem function with an interactable that is not an Item ! "


clearWrittenText : Maybe Interactable -> Maybe Interactable
clearWrittenText mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | writtenContent = Nothing })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use clearWrittenText function with an interactable that is not an Item ! "


getItemWrittenContent : Maybe Interactable -> Maybe String
getItemWrittenContent mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            idata.writtenContent

        _ ->
            Nothing


checkIfAnswerCorrect : QuestionAnswer -> String -> CheckAnswerData -> Manifest -> Maybe Interactable -> Maybe Interactable
checkIfAnswerCorrect questionAns playerAnswer checkAnsData manifest mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            let
                correct =
                    "  \n ___CORRECT_ANSWER___"

                incorrect =
                    "  \n ___INCORRECT_ANSWER___"

                reach_max_nr_tries =
                    "___REACH_MAX_NR_TRIES___"

                playerAns =
                    if checkAnsData.answerFeedback == JustPlayerAnswer || checkAnsData.answerFeedback == HeaderAndAnswer || checkAnsData.answerFeedback == HeaderAnswerAndCorrectIncorrect then
                        "  \n ___YOUR_ANSWER___" ++ " " ++ playerAnswer

                    else
                        ""

                answerFeedback =
                    correct
                        ++ "  \n"
                        |> (\x ->
                                if checkAnsData.answerFeedback == HeaderAnswerAndCorrectIncorrect then
                                    x

                                else
                                    ""
                           )

                ansRight =
                    playerAns ++ answerFeedback

                mbMaxNrTries =
                    checkAnsData.mbMaxNrTries

                getAnsWrong nrTriesArg mbTheMax =
                    let
                        ansFeedback =
                            case mbTheMax of
                                Just theMax ->
                                    if nrTriesArg >= theMax then
                                        "  \n" ++ " " ++ reach_max_nr_tries

                                    else
                                        incorrect
                                            ++ "  \n"
                                            ++ " "
                                            ++ "___NR_TRIES_LEFT___"
                                            ++ " "
                                            ++ String.fromInt (theMax - nrTriesArg)

                                Nothing ->
                                    incorrect
                    in
                    playerAns
                        ++ (if checkAnsData.answerFeedback == HeaderAnswerAndCorrectIncorrect then
                                ansFeedback

                            else
                                ""
                           )

                nrTries =
                    let
                        previousNrTries =
                            getICounterValue "nrIncorrectAnswers" mbinteractable
                                |> Maybe.withDefault 0
                    in
                    if playerAnswer /= "" then
                        previousNrTries + 1

                    else
                        previousNrTries

                makeItUnanswarableIfReachedMaxTries : Maybe Int -> Int -> Maybe Interactable -> Maybe Interactable
                makeItUnanswarableIfReachedMaxTries mbMaxnr nrtries mbinter =
                    case mbMaxnr of
                        Just maxnr ->
                            if nrtries >= maxnr then
                                --makeItemUnwritable mbinter
                                makeItUnanswerable mbinter

                            else
                                mbinter

                        Nothing ->
                            mbinter

                ( theCorrectAnswers, bEval ) =
                    case questionAns of
                        ListOfAnswersAndFunctions lstrs lfns ->
                            ( lstrs
                            , List.map (\fn -> fn playerAnswer manifest) lfns
                                |> List.foldl (\b1 b2 -> b1 || b2) False
                            )

                thesuccessTextDict =
                    generateFeedbackTextDict checkAnsData.correctAnsTextDict playerAnswer manifest

                theInsuccessTextDict =
                    generateFeedbackTextDict checkAnsData.incorrectAnsTextDict playerAnswer manifest

                otherInterAttribsRelatedCWcmds : List ChangeWorldCommand
                otherInterAttribsRelatedCWcmds =
                    List.foldl (\( otherInterId, attrId, attrValue ) y -> CreateAttributeIfNotExistsAndOrSetValue attrValue attrId otherInterId :: y) [] checkAnsData.lotherInterAttrs

                theMbInteractable =
                    if nrTries > Maybe.withDefault 1000000 mbMaxNrTries then
                        mbinteractable
                            |> makeItUnanswerable

                    else if
                        playerAnswer
                            == ""
                            || Dict.get "isCorrectlyAnswered" idata.attributes
                            == Just (Abool True)
                    then
                        mbinteractable
                        -- if no answer was provided or correct answer was previously provided returns the exact same maybe interactable

                    else if (List.length theCorrectAnswers > 0 && comparesEqualToAtLeastOne playerAnswer theCorrectAnswers checkAnsData.answerCase checkAnsData.answerSpaces) || bEval then
                        Just (Item { idata | writtenContent = Just ansRight })
                            |> makeItUnanswerable
                            |> createAttributeIfNotExistsAndOrSetValue (Astring playerAnswer) "playerAnswer"
                            |> createAttributeIfNotExistsAndOrSetValue (Abool True) "isCorrectlyAnswered"
                            |> removeAttributeIfExists "isIncorrectlyAnswered"
                            |> createAttributeIfNotExistsAndOrSetValue (Astring "___QUESTION_ANSWERED___") "narrativeHeader"
                            |> createAttributeIfNotExistsAndOrSetValue (ADictStringListString thesuccessTextDict) "additionalTextDict"
                            |> createAttributesIfNotExistsAndOrSetValue checkAnsData.lnewAttrs
                            |> setNextChangeWorldCommandsToBeExecuted otherInterAttribsRelatedCWcmds

                    else
                        Just (Item { idata | writtenContent = Just (getAnsWrong nrTries mbMaxNrTries) })
                            |> createAttributeIfNotExistsAndOrSetValue (Astring playerAnswer) "playerAnswer"
                            |> createAttributeIfNotExistsAndOrSetValue (Abool True) "isIncorrectlyAnswered"
                            |> removeAttributeIfExists "isCorrectlyAnswered"
                            |> createAttributeIfNotExistsAndOrSetValue (ADictStringListString theInsuccessTextDict) "additionalTextDict"
                            |> createCounterIfNotExists "nrIncorrectAnswers"
                            |> makeItUnanswarableIfReachedMaxTries mbMaxNrTries nrTries
                            |> increaseCounter "nrIncorrectAnswers"
            in
            theMbInteractable

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use checkIfAnswerCorrect function with an interactable that is not an Item ! "


generateFeedbackTextDict : Dict String FeedbackText -> String -> Manifest -> Dict String (List String)
generateFeedbackTextDict dcf answerOrChoice manifest =
    let
        fnFeedbackText : String -> FeedbackText -> List String
        fnFeedbackText lgId choiceFeedback =
            case choiceFeedback of
                NoFeedbackText ->
                    []

                SimpleText ls ->
                    ls

                FnEvalText fn ->
                    let
                        afterFunc =
                            fn answerOrChoice manifest
                    in
                    afterFunc

        dAfterFunc =
            Dict.map (\lgId cf -> fnFeedbackText lgId cf) dcf
    in
    dAfterFunc


checkAndActIfChosenOptionIs : String -> List CheckOptionData -> String -> Manifest -> Maybe Interactable -> Maybe Interactable
checkAndActIfChosenOptionIs playerChoice lcOptionData optionId manifest mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            let
                choiceStr =
                    "  \n ___YOUR_CHOICE___" ++ " " ++ playerChoice

                choiceComparesEqualToValToMatch choiceMatches =
                    case choiceMatches of
                        MatchStringValue strToMatch ->
                            if playerChoice == strToMatch then
                                True

                            else
                                False

                        MatchAnyNonEmptyString ->
                            if playerChoice /= "" then
                                True

                            else
                                False

                mbFindMatched =
                    List.filter (\x -> choiceComparesEqualToValToMatch x.choiceMatches) lcOptionData
                        |> List.head

                resetOptionId =
                    "reset_" ++ optionId

                isResetPossible =
                    getAttributeByIdAndInteractableId "isResetOptionPossible" optionId manifest
                        |> Maybe.withDefault (Abool False)

                theMbInteractable =
                    if playerChoice == "" && Dict.get "chosenOption" idata.attributes == Nothing then
                        mbinteractable
                            |> removeAttributeIfExists "suggestedInteraction"

                    else if
                        playerChoice
                            == ""
                            || Dict.get "chosenOption" idata.attributes
                            /= Nothing
                    then
                        mbinteractable
                        -- if no choice or it was already chosen before it doesnt check
                        -- and doesnt make any alteration

                    else if mbFindMatched /= Nothing then
                        case mbFindMatched of
                            Just cOptionData ->
                                let
                                    theTextDict =
                                        generateFeedbackTextDict cOptionData.choiceFeedbackText playerChoice manifest

                                    otherInterAttribsRelatedCWcmds =
                                        List.foldl (\( otherInterId, attrId, attrValue ) y -> CreateAttributeIfNotExistsAndOrSetValue attrValue attrId otherInterId :: y) [] cOptionData.lotherInterAttrs
                                in
                                Just (Item { idata | writtenContent = Just choiceStr })
                                    |> createAttributeIfNotExistsAndOrSetValue (Astring playerChoice) "chosenOption"
                                    |> createAttributeIfNotExistsAndOrSetValue (ADictStringListString theTextDict) "additionalTextDict"
                                    |> createAttributesIfNotExistsAndOrSetValue cOptionData.lnewAttrs
                                    |> setNextChangeWorldCommandsToBeExecuted (List.append cOptionData.lnewCWcmds otherInterAttribsRelatedCWcmds)
                                    |> removeAttributeIfExists "answerOptionsList"
                                    |> makeItemUnwritable
                                    |> (\mbinter ->
                                            if isResetPossible == Abool True then
                                                createAttributeIfNotExistsAndOrSetValue (Astring resetOptionId) "suggestedInteraction" mbinter

                                            else
                                                mbinter
                                       )

                            Nothing ->
                                mbinteractable

                    else
                        mbinteractable
            in
            theMbInteractable

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use checkIfAnswerCorrect function with an interactable that is not an Item ! "


resetOption : Maybe Interactable -> Maybe Interactable
resetOption mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            Just (Item { idata | writtenContent = Nothing })
                |> removeAttributeIfExists "chosenOption"
                |> removeAttributeIfExists "additionalTextDict"
                |> (\mbint ->
                        if getInteractableAttribute "displayOptionButtons" mbint == Just (Abool True) then
                            reactivateMultiChoiceFromBackup mbint

                        else
                            makeItemWritable mbint
                   )

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use resetOption function with an interactable that is not an Item ! "


{-| This change should only be used in conjunction with isChosenOptionEqualTo as a condition
if that condition is verified we know that playerChoice is equal to matchedValue and we can just call
checkAndActIfChosenOptionIs
-}



--processChosenOptionEqualTo : CheckOptionData -> Manifest -> Maybe Interactable -> Maybe Interactable
--processChosenOptionEqualTo cOptionData manifest mbinteractable =
--    checkAndActIfChosenOptionIs cOptionData.choiceMatches [ cOptionData ] manifest mbinteractable


moveCharacterToLocation : String -> Maybe Interactable -> Maybe Interactable
moveCharacterToLocation locationId mbInteractable =
    case mbInteractable of
        Just (Character cdata) ->
            -- still have to check if location exists
            Just (Character { cdata | characterPlacement = CharacterInLocation locationId })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveCharacterToLocation function with an interactable that is not a Character ! "


moveCharacterOffScreen : Maybe Interactable -> Maybe Interactable
moveCharacterOffScreen mbInteractable =
    case mbInteractable of
        Just (Character cdata) ->
            Just (Character { cdata | characterPlacement = CharacterOffScreen })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveCharacterOffScreen function with an interactable that is not a Character ! "


itemIsInCharacterInventory : String -> String -> Manifest -> Bool
itemIsInCharacterInventory charId itemId manifest =
    getItemsInCharacterInventory charId manifest
        |> List.any ((==) itemId)


itemIsCorrectlyAnswered : String -> Manifest -> Bool
itemIsCorrectlyAnswered id manifest =
    attrValueIsEqualTo (Abool True) "isCorrectlyAnswered" id manifest


{-| This includes both the cases when Item is IncorrectlyAnswered or NotAnswered
-}
itemIsNotCorrectlyAnswered : String -> Manifest -> Bool
itemIsNotCorrectlyAnswered id manifest =
    not (itemIsCorrectlyAnswered id manifest)


itemIsIncorrectlyAnswered : String -> Manifest -> Bool
itemIsIncorrectlyAnswered id manifest =
    attrValueIsEqualTo (Abool True) "isIncorrectlyAnswered" id manifest


itemIsNotAnswered : String -> Manifest -> Bool
itemIsNotAnswered id manifest =
    not (itemIsCorrectlyAnswered id manifest) && not (itemIsIncorrectlyAnswered id manifest)


characterIsInLocation : String -> String -> Manifest -> Bool
characterIsInLocation characterid currentLocation manifest =
    getCharactersInLocation currentLocation manifest
        |> List.any ((==) characterid)


itemIsInLocation : String -> String -> Manifest -> Bool
itemIsInLocation itemid currentLocation manifest =
    getItemsInLocation currentLocation manifest
        |> List.any ((==) itemid)


itemIsNotInLocation : String -> String -> Manifest -> Bool
itemIsNotInLocation itemid currentLocation manifest =
    not (itemIsInLocation itemid currentLocation manifest)


itemIsOffScreen : String -> Manifest -> Bool
itemIsOffScreen id manifest =
    case Dict.get id manifest of
        Just interactable ->
            case interactable of
                Item idata ->
                    if idata.itemPlacement == ItemOffScreen then
                        True

                    else
                        False

                _ ->
                    False

        Nothing ->
            False


itemIsInAnyLocationOrCharacterInventory : String -> String -> Manifest -> Bool
itemIsInAnyLocationOrCharacterInventory charId itemId manifest =
    case Dict.get itemId manifest of
        Just interactable ->
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInCharacterInventory charId_ ->
                            if charId == charId_ then
                                True

                            else
                                False

                        ItemInLocation locid ->
                            True

                        ItemOffScreen ->
                            False

                _ ->
                    False

        Nothing ->
            False


itemIsInAnyLocationOrAnyCharacterInventory : String -> Manifest -> Bool
itemIsInAnyLocationOrAnyCharacterInventory itemId manifest =
    case Dict.get itemId manifest of
        Just interactable ->
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInCharacterInventory _ ->
                            True

                        ItemInLocation locid ->
                            True

                        ItemOffScreen ->
                            False

                _ ->
                    False

        Nothing ->
            False


counterExists : String -> String -> Manifest -> Bool
counterExists counterId interId manifest =
    let
        helperFunc : String -> { a | attributes : Dict String AttrTypes } -> Bool
        helperFunc theCounterId dataRecord =
            case Dict.get ("counter_" ++ theCounterId) dataRecord.attributes of
                Nothing ->
                    False

                Just val ->
                    True
    in
    case Dict.get interId manifest of
        Just (Item idata) ->
            helperFunc counterId idata

        Just (Character cdata) ->
            helperFunc counterId cdata

        Just (Location ldata) ->
            helperFunc counterId ldata

        Nothing ->
            False


counterLessThen : Int -> String -> String -> Manifest -> Bool
counterLessThen val counterId interId manifest =
    let
        helperFunc : String -> { a | attributes : Dict String AttrTypes } -> Bool
        helperFunc theCounterId dataRecord =
            case Dict.get ("counter_" ++ theCounterId) dataRecord.attributes of
                Nothing ->
                    False

                Just attrvalue ->
                    case attrvalue of
                        AnInt value ->
                            if value < val then
                                True

                            else
                                False

                        _ ->
                            False
    in
    case Dict.get interId manifest of
        Just (Item idata) ->
            helperFunc counterId idata

        Just (Character cdata) ->
            helperFunc counterId cdata

        Just (Location ldata) ->
            helperFunc counterId ldata

        Nothing ->
            False


counterGreaterThenOrEqualTo : Int -> String -> String -> Manifest -> Bool
counterGreaterThenOrEqualTo val counterId interId manifest =
    counterExists counterId interId manifest
        && not (counterLessThen val counterId interId manifest)


getCounterValue : String -> String -> Manifest -> Maybe Int
getCounterValue counterId interId manifest =
    Dict.get interId manifest
        |> getICounterValue counterId


{-| similar to getCounterValue but takes as arg a maybe Interactable instead of an interactableId
-}
getICounterValue : String -> Maybe Interactable -> Maybe Int
getICounterValue counterId mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Dict.get ("counter_" ++ counterId) idata.attributes
                |> convertMbAttrTypeToMbInt

        Just (Character cdata) ->
            Dict.get ("counter_" ++ counterId) cdata.attributes
                |> convertMbAttrTypeToMbInt

        Just (Location ldata) ->
            Dict.get ("counter_" ++ counterId) ldata.attributes
                |> convertMbAttrTypeToMbInt

        Nothing ->
            Nothing


convertMbAttrTypeToMbInt : Maybe AttrTypes -> Maybe Int
convertMbAttrTypeToMbInt mbanint =
    case mbanint of
        Nothing ->
            Nothing

        Just val ->
            case val of
                AnInt ival ->
                    Just ival

                _ ->
                    Nothing


attrValueIsEqualTo : AttrTypes -> String -> String -> Manifest -> Bool
attrValueIsEqualTo attrValue attrId interactableId manifest =
    case Dict.get interactableId manifest of
        Nothing ->
            False

        Just interactable ->
            case interactable of
                Item idata ->
                    if Dict.get attrId idata.attributes == Just attrValue then
                        True

                    else
                        False

                Character cdata ->
                    if Dict.get attrId cdata.attributes == Just attrValue then
                        True

                    else
                        False

                Location ldata ->
                    if Dict.get attrId ldata.attributes == Just attrValue then
                        True

                    else
                        False


{-| sets attribute value only if attribute was previously created
-}
setAttributeValue : AttrTypes -> String -> Maybe Interactable -> Maybe Interactable
setAttributeValue attrValue attrId mbinteractable =
    let
        getNewDataRecord : AttrTypes -> String -> { a | attributes : Dict String AttrTypes } -> { a | attributes : Dict String AttrTypes }
        getNewDataRecord theattrValue theattrId dataRecord =
            let
                newAttributes =
                    case Dict.get theattrId dataRecord.attributes of
                        Nothing ->
                            dataRecord.attributes

                        Just val ->
                            Dict.update theattrId (\_ -> Just theattrValue) dataRecord.attributes

                newDataRecord =
                    { dataRecord | attributes = newAttributes }
            in
            newDataRecord
    in
    case mbinteractable of
        Just (Item idata) ->
            Just (Item <| getNewDataRecord attrValue attrId idata)

        Just (Character cdata) ->
            Just (Character <| getNewDataRecord attrValue attrId cdata)

        Just (Location ldata) ->
            Just (Location <| getNewDataRecord attrValue attrId ldata)

        Nothing ->
            Nothing


createAttributeIfNotExistsAndOrSetValue : AttrTypes -> String -> Maybe Interactable -> Maybe Interactable
createAttributeIfNotExistsAndOrSetValue theVal attrId mbinteractable =
    createAttributeIfNotExists theVal attrId mbinteractable
        |> setAttributeValue theVal attrId


{-| tries to create and or set the value of several attributes on the interactable given by the list of tuples
first element of tuple is attribute id and second is the attribute value
-}
createAttributesIfNotExistsAndOrSetValue : List ( String, AttrTypes ) -> Maybe Interactable -> Maybe Interactable
createAttributesIfNotExistsAndOrSetValue ltupattrs mbinteractable =
    case ltupattrs of
        [] ->
            mbinteractable

        head :: rest ->
            createAttributeIfNotExistsAndOrSetValue (Tuple.second head) (Tuple.first head) mbinteractable
                |> createAttributesIfNotExistsAndOrSetValue rest


createOrSetAttributeValueFromOtherInterAttr : String -> String -> String -> Manifest -> Maybe Interactable -> Maybe Interactable
createOrSetAttributeValueFromOtherInterAttr attrId otherInterAtrrId otherInterId manifest mbinteractable =
    let
        mbAttrVal =
            getInteractableAttribute otherInterAtrrId (Dict.get otherInterId manifest)
    in
    -- if the attribute doesnt exist in the other interactable it doesn't create or set any attribute
    case mbAttrVal of
        Just theAttrVal ->
            createAttributeIfNotExistsAndOrSetValue theAttrVal attrId mbinteractable

        Nothing ->
            mbinteractable
                |> writeInteractionIncident "warning" ("Trying to use createOrSetAttributeValueFromOtherInterAttr function but attribute in other interactable doesnt exist ( or other interactable doesnt exist ) ! attributeId : " ++ attrId ++ " , otherInteractableId : " ++ otherInterId)


removeAttributeIfExists : String -> Maybe Interactable -> Maybe Interactable
removeAttributeIfExists attrId mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            let
                newAttributes =
                    Dict.remove attrId idata.attributes
            in
            Just (Item { idata | attributes = newAttributes })

        Just (Character cdata) ->
            let
                newAttributes =
                    Dict.remove attrId cdata.attributes
            in
            Just (Character { cdata | attributes = newAttributes })

        Just (Location ldata) ->
            let
                newAttributes =
                    Dict.remove attrId ldata.attributes
            in
            Just (Location { ldata | attributes = newAttributes })

        Nothing ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to remove attribute from  interactable that doesnt exist "


getInteractableAttribute : String -> Maybe Interactable -> Maybe AttrTypes
getInteractableAttribute attrId mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            Dict.get attrId idata.attributes

        Just (Character cdata) ->
            Dict.get attrId cdata.attributes

        Just (Location ldata) ->
            Dict.get attrId ldata.attributes

        _ ->
            Nothing


getAttributeByIdAndInteractableId : String -> String -> Manifest -> Maybe AttrTypes
getAttributeByIdAndInteractableId attrId interactableId manifest =
    case Dict.get interactableId manifest of
        Just (Item idata) ->
            Dict.get attrId idata.attributes

        Just (Character cdata) ->
            Dict.get attrId cdata.attributes

        Just (Location ldata) ->
            Dict.get attrId ldata.attributes

        _ ->
            Nothing


setNextChangeWorldCommandsToBeExecuted : List ChangeWorldCommand -> Maybe Interactable -> Maybe Interactable
setNextChangeWorldCommandsToBeExecuted lcwcmds mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | newCWCmds = lcwcmds })

        Just (Character cdata) ->
            Just (Character { cdata | newCWCmds = lcwcmds })

        Just (Location ldata) ->
            Just (Location { ldata | newCWCmds = lcwcmds })

        Nothing ->
            mbInteractable


clearNextChangeWorldCommandsToBeExecuted : Maybe Interactable -> Maybe Interactable
clearNextChangeWorldCommandsToBeExecuted mbInteractable =
    setNextChangeWorldCommandsToBeExecuted [] mbInteractable


comparesEqual : String -> String -> Types.AnswerCase -> Types.AnswerSpaces -> Bool
comparesEqual str1 str2 ansCase ansSpaces =
    let
        ( str1_, str2_ ) =
            if ansCase == CaseInsensitiveAnswer then
                ( String.toLower str1, String.toLower str2 )

            else
                ( str1, str2 )

        ( str1Alt, str2Alt ) =
            if ansSpaces == AnswerSpacesDontMatter then
                ( eliminateAllWhiteSpaces str1_, eliminateAllWhiteSpaces str2_ )

            else
                ( str1_, str2_ )
    in
    if str1Alt == str2Alt then
        True

    else
        False


comparesEqualToAtLeastOne : String -> List String -> Types.AnswerCase -> Types.AnswerSpaces -> Bool
comparesEqualToAtLeastOne str1 lstrs ansCase ansSpaces =
    List.map (\x -> comparesEqual str1 x ansCase ansSpaces) lstrs
        |> List.filter (\x -> x == True)
        |> List.isEmpty
        |> not


eliminateAllWhiteSpaces : String -> String
eliminateAllWhiteSpaces theStr =
    theStr
        |> String.toList
        |> List.filter (\c -> c /= ' ')
        |> String.fromList
