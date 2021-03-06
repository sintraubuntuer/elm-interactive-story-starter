module ClientTypes exposing
    ( AudioFileInfo
    , EndScreenInfo
    , LanguageId
    , LanguageStorySnippets
    , Msg(..)
    , SaveHistoryRecord
    , SettingsModel
    , StartScreenInfo
    , StorySnippet
    , ToSettingsMsg(..)
    )

--import Geolocation

import Dict exposing (Dict)
import GpsUtils
import Http
import Types as EngineTypes exposing (AnswerInfo, InteractionExtraInfo)


type Msg
    = StartMainGame
    | StartMainGameNewPlayerName String
    | InteractSendingText String String
    | Interact String
    | InteractStepTwo String EngineTypes.InteractionExtraInfo
    | InteractStepThree String EngineTypes.InteractionExtraInfo
    | AnswerChecked String EngineTypes.ExtraInfoWithPendingChanges (Result Http.Error EngineTypes.AnswerInfo)
    | NewUserSubmitedText String
    | ChangeOptionDisplayLanguage String
    | ChangeOptionDontCheckGps Bool
    | NewCoordsForInterId { interactableId : String, latitude : Float, longitude : Float }
    | NewCoordsForInterIdFailed String
    | NotInTheZone String (Maybe GpsUtils.GpsZone) GpsUtils.GeolocationInfo Float
    | CloseAlert
    | ToggleShowExpandedSettings
    | ChangeOptionAudioAutoplay Bool
    | LayoutWithSideBar Bool
    | ToggleShowHideSaveLoadBtns
    | SaveHistory
    | RequestForStoredHistory
    | LoadHistory { playerName : String, lInteractions : List SaveHistoryRecord, lPrandomFloats : List Float }
    | ProcessLoadHistory (List ( String, InteractionExtraInfo )) SettingsModel
    | ExitToFinalScreen
    | Loaded
    | NewRandomElemsAtGameStart (List Float)
    | FillRandomElemsList (List Float)


type alias SaveHistoryRecord =
    { interactableId : String
    , inputText : String
    , inputTextForBackend : String
    , geolocationInfoText : String
    , currentLocation : String
    , mbMatchedRuleId : String
    }


type ToSettingsMsg
    = SetDontNeedToBeInZone Bool
    | SetDisplayLanguage String
    | SetAvailableLanguages (Dict String String)
    | SettingsToggleShowExpanded
    | SettingsChangeOptionAutoplay Bool
    | SettingsToggleShowHideSaveLoadBtns
    | SettingsLayoutWithSidebar Bool
    | SettingsShowExitToFinalScreenButton
    | SettingsHideExitToFinalScreenButton


type alias SettingsModel =
    { availableLanguages : Dict String String -- key : LanguageId , val : language as string
    , displayLanguage : String
    , gpsOptionsEnabled : Bool -- this control whether gpsOptions appear on sidebar and are available to be changed by the user
    , dontNeedToBeInZone : Bool
    , audioOptionsEnabled : Bool
    , audioAutoplay : Bool
    , layoutWithSidebar : Bool
    , showAnswerBoxInSideBar : Bool
    , showExpandedSettings : Bool
    , saveLoadEnabled : Bool -- this controls whether save/load options appear on sidebar and are available to be changed by the user
    , showSaveLoad : Bool
    , showExitToFinalScreenButton : Bool
    }


type alias AudioFileInfo =
    { displayName : String
    , fileName : String
    , mbAbsoluteUrl : Maybe String
    }


type alias StorySnippet =
    { interactableName : String
    , interactableId : String
    , isWritable : Bool
    , interactableCssSelector : String
    , narrative : String
    , mbAudio : Maybe AudioFileInfo
    , mbSuggestedInteractionId : Maybe String
    , suggestedInteractionCaption : String
    , mbSuggestedInteractionName : Maybe String
    , isLastInZipper : Bool
    }


type alias LanguageId =
    String


type alias LanguageStorySnippets =
    { interactableName : String
    , interactableCssSelector : String
    , narrativesDict : Dict LanguageId String
    }


type alias StartScreenInfo =
    { mainImage : String
    , title_line1 : String
    , title_line2 : String
    , byLine : String
    , smallIntro : String
    , tboxNamePlaceholder : String
    }


type alias EndScreenInfo =
    { mainImage : String
    , congratsMessage1 : String
    , congratsMessage2 : String
    , endScreenText : String
    }
