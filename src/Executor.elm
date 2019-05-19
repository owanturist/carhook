module Executor exposing (main)

import Api
import Browser
import Browser.Navigation
import Dict exposing (Dict)
import Error
import Glob exposing (Glob)
import Html exposing (Html, a, div, form, i, nav, span, text)
import Html.Attributes
import Http
import ID exposing (ID)
import RemoteData exposing (RemoteData(..))
import Status
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser exposing ((</>), Parser, s)
import ViewReport
import YaMap


insertToDict : { entity | id : ID supported } -> Dict String { entity | id : ID supported } -> Dict String { entity | id : ID supported }
insertToDict entity dict =
    Dict.insert (ID.toString entity.id) entity dict



-- H O M E


type alias Home =
    { reports : RemoteData Http.Error (List (ID { report : () }))
    , reportsDict : Dict String Api.Report
    }


initHome : ( Home, Cmd HomeMsg )
initHome =
    ( Home Loading Dict.empty
    , Cmd.batch
        [ Cmd.map GetListOfReportsDone Api.getListOfReports
        , YaMap.init "ya-map" True
        ]
    )


type HomeMsg
    = GetListOfReportsDone (Result Http.Error (List Api.Report))
    | OpenReport (ID { report : () })


updateHome : HomeMsg -> Glob -> Home -> ( Home, Cmd HomeMsg )
updateHome msg glob model =
    case msg of
        GetListOfReportsDone (Err error) ->
            ( { model | reports = Failure error }
            , Cmd.none
            )

        GetListOfReportsDone (Ok reports) ->
            let
                reportsList =
                    List.filter
                        (\report ->
                            case report.status of
                                Status.Ready ->
                                    True

                                Status.InProgress _ ->
                                    True

                                Status.Accepted _ ->
                                    True

                                _ ->
                                    False
                        )
                        reports

                reportsDict =
                    List.foldr insertToDict Dict.empty reports
            in
            ( { model
                | reports = Success (List.map .id reportsList)
                , reportsDict = reportsDict
              }
            , List.map (\report -> ( report.id, report.address )) reportsList
                |> YaMap.setAddresses
            )

        OpenReport reportId ->
            ( model
            , Browser.Navigation.pushUrl glob.key (routeToString (ToReport reportId))
            )


homeSubscriptions : Home -> Sub HomeMsg
homeSubscriptions model =
    Sub.map OpenReport YaMap.onReport


viewHome : Home -> Html HomeMsg
viewHome model =
    div
        [ Html.Attributes.class "bg-light"
        , Html.Attributes.id "ya-map"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "100%"
        ]
        []



-- M O D E L


type Route
    = ToHome
    | ToReport (ID { report : () })
    | ToNotFound


routeToString : Route -> String
routeToString route =
    case route of
        ToHome ->
            absolute [] []

        ToReport reportId ->
            absolute [ "report", ID.toString reportId ] []

        ToNotFound ->
            absolute [] []


routeParser : Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map ToHome Url.Parser.top
        , Url.Parser.map ToReport (s "report" </> ID.parser)
        ]


parseRoute : Url -> Route
parseRoute =
    Maybe.withDefault ToNotFound << Url.Parser.parse routeParser


type Page
    = VoidPage
    | HomePage Home
    | ReportPage (ID { report : () }) ViewReport.Model


initPage : Glob -> Route -> ( Page, Cmd Msg )
initPage glob route =
    case route of
        ToHome ->
            Tuple.mapBoth HomePage (Cmd.map HomeMsg) initHome

        ToReport reportId ->
            Tuple.mapBoth (ReportPage reportId) (Cmd.map ViewReportMsg) (ViewReport.init reportId)

        ToNotFound ->
            ( VoidPage
            , Browser.Navigation.replaceUrl glob.key (routeToString ToHome)
            )


type Model
    = Model Glob Page


init : () -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags initialUrl key =
    let
        glob =
            Glob key
    in
    Tuple.mapFirst (Model glob) (initPage glob (parseRoute initialUrl))



-- U P D A T E


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | HomeMsg HomeMsg
    | ViewReportMsg ViewReport.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model glob page) =
    case ( msg, page ) of
        ( UrlRequested (Browser.Internal url), _ ) ->
            ( Model glob page
            , Cmd.batch
                [ Browser.Navigation.pushUrl glob.key (Url.toString url)
                , case page of
                    HomePage _ ->
                        YaMap.destroy

                    ReportPage _ _ ->
                        Cmd.map ViewReportMsg ViewReport.destroy

                    _ ->
                        Cmd.none
                ]
            )

        ( UrlRequested (Browser.External uri), _ ) ->
            ( Model glob page
            , Browser.Navigation.load uri
            )

        ( UrlChanged url, _ ) ->
            Tuple.mapFirst (Model glob) (initPage glob (parseRoute url))

        ( HomeMsg msgOfHome, HomePage homePage ) ->
            Tuple.mapBoth
                (Model glob << HomePage)
                (Cmd.map HomeMsg)
                (updateHome msgOfHome glob homePage)

        ( HomeMsg _, _ ) ->
            ( Model glob page, Cmd.none )

        ( ViewReportMsg msgOfViewReport, ReportPage viewReportId viewReportPage ) ->
            let
                ( nextViewReportPage, cmdOfViewReport ) =
                    ViewReport.update msgOfViewReport viewReportId viewReportPage
            in
            ( Model glob (ReportPage viewReportId nextViewReportPage)
            , Cmd.map ViewReportMsg cmdOfViewReport
            )

        ( ViewReportMsg _, _ ) ->
            ( Model glob page, Cmd.none )



-- S U B S C R I P T I O N


subscriptions : Model -> Sub Msg
subscriptions (Model _ page) =
    case page of
        HomePage homePage ->
            Sub.map HomeMsg (homeSubscriptions homePage)

        _ ->
            Sub.none



-- V I E W


viewNav : Html msg
viewNav =
    nav
        [ Html.Attributes.class "executor__nav navbar navbar-light bg-light"
        ]
        [ span [] []
        , a
            [ Html.Attributes.class "executor__logo navbar-brand m-0"
            , Html.Attributes.href (routeToString ToHome)
            , Html.Attributes.tabindex 1
            ]
            [ text "c a r "
            , i [ Html.Attributes.class "fa fa-car" ] []
            , text " h o o k"
            ]
        , span [] []
        ]


view : Model -> Browser.Document Msg
view (Model _ page) =
    Browser.Document "Car Hook | Executor"
        [ div
            [ Html.Attributes.class "executor"
            ]
            [ viewNav
            , case page of
                VoidPage ->
                    text ""

                HomePage homePage ->
                    Html.map HomeMsg (viewHome homePage)

                ReportPage _ reportPage ->
                    Html.map ViewReportMsg (ViewReport.view False reportPage)
            ]
        ]



-- M A I N


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        }
