module Settings exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Http
import Models.User exposing (Settings)
import State.Settings exposing (..)
import State.Util exposing (SendingStatus(..))
import Util exposing (UpdateMessage(..))

type Msg
  = GetSettings Settings
  | UpdateSettings (Result Http.Error ())
  | ToggleEmailsForAnswers Settings
  | ChangeEmailAddress Settings String
  | Save Settings

getSettings : Cmd (UpdateMessage Msg)
getSettings =
  Http.get "/api/asetukset" Models.User.settingsDecoder
    |> Util.errorHandlingSend GetSettings

updateSettings : Settings -> Cmd (UpdateMessage Msg)
updateSettings settings =
  Util.put "/api/asetukset" (Models.User.settingsEncode settings)
    |> Http.send (LocalUpdateMessage << UpdateSettings)

initTasks : Cmd (UpdateMessage Msg)
initTasks = getSettings

update : Msg -> Model -> (Model, Cmd (UpdateMessage Msg))
update msg model =
  case msg of
    GetSettings settings ->
      { model | settings = Just settings } ! []

    UpdateSettings (Ok _) ->
      { model | sending = FinishedSuccess "" } ! []

    UpdateSettings (Err _) ->
      { model | sending = FinishedFail } ! []

    ToggleEmailsForAnswers settings ->
      { model
        | sending = NotSending
        , settings = Just
          { settings
            | emails_for_answers = not settings.emails_for_answers }} ! []

    ChangeEmailAddress settings str ->
      { model
        | sending = NotSending
        , settings = Just
          { settings
            | email_address = str }} ! []

    Save settings ->
      { model | sending = Sending } ! [ updateSettings settings ]



view : Model -> H.Html Msg
view model =
  model.settings
    |> Maybe.map (viewSettings model)
    |> Maybe.withDefault (H.div [] [])

viewSettings : Model -> Settings -> H.Html Msg
viewSettings model settings =
  H.div
    []
    [ H.h1 [] [ H.text "Asetukset" ]
    , H.form
      [ ]
      [ H.div
        [ A.class "form-group"
        ]
        [ H.label
          [ A.for "email-address"
          ]
          [ H.text "Sähköpostiosoite" ]
        , H.input
          [ A.type_ "text"
          , A.class "form-control"
          , A.id "email-address"
          , A.value settings.email_address
          , E.onInput (ChangeEmailAddress settings)
          ]
          []
        ]
      ]
      , H.div
        [ A.class "checkbox" ]
        [ H.label
          []
          [ H.input
            [ A.type_ "checkbox"
            , E.onClick <| ToggleEmailsForAnswers settings
            , A.checked settings.emails_for_answers
            ]
            []
          , H.text "Lähetä ilmoitus sähköpostiin saapuneista vastauksista"
          ]
        ]
    , H.button
      [ E.onClick (Save settings)
      , A.class "btn btn-default"
      ]
      [ H.text "Tallenna" ]
    , H.p
      []
      [ H.text <| sendingToText model.sending ]
    ]


sendingToText : SendingStatus -> String
sendingToText sending =
  case sending of
    NotSending -> ""
    Sending -> "Tallenetaan…"
    FinishedSuccess _ -> "Tallennus onnistui"
    FinishedFail -> "Tallenuksessa meni jotain pieleen"
