require('./src/executor.pcss');

const compiled = require('./src/Executor.elm');


function noop() {}

ymaps.ready(function() {
    var yaMap = null;
    var afterMapInited = noop;
    var app = compiled.Elm.Executor.init();

    app.ports.ya_map__init.subscribe(function(payload) {
        setTimeout(() => {
            ymaps.geolocation.get().then(function(result) {
                var mapContainer = document.getElementById(payload.nodeId);
                var bounds = result.geoObjects.get(0).properties.get('boundedBy');
                    // Рассчитываем видимую область для текущей положения пользователя.
                var mapState = ymaps.util.bounds.getCenterAndZoom(
                    bounds,
                    [mapContainer.clientWidth, mapContainer.clientHeight]
                );
                createMap(payload, mapState);

                result.geoObjects.options.set('preset', 'islands#redCircleIcon');
                yaMap.geoObjects.add(result.geoObjects);

            }, function() {
                // Если местоположение невозможно получить, то просто создаем карту.
                createMap(payload, {
                    center: [55.0252534, 82.911067]
                });
            });
        }, 50);
    });

    function createMap(payload, config) {
        if (yaMap !== null) {
            yaMap.destroy();
        }

        yaMap = new ymaps.Map(payload.nodeId, Object.assign({
            controls: [ 'zoomControl', 'geolocationControl' ]
        }, config, {
            zoom: 13
        }))

        afterMapInited();
        afterMapInited = noop;
    }

    app.ports.ya_map__set_addresses.subscribe(function(addresses) {
        if (yaMap == null) {
            afterMapInited = function() {
                drawAddresses(addresses);
            }
        } else {
            drawAddresses(addresses);
        }
    });

    function drawAddresses(addresses) {
        addresses.forEach(function(payload) {
            ymaps.geocode(payload.address, {
                results: 1
            }).then(function(result) {
                var firstGeoObject = result.geoObjects.get(0);
                // Координаты геообъекта.
                var coords = firstGeoObject.geometry.getCoordinates();
                // Область видимости геообъекта.
                var bounds = firstGeoObject.properties.get('boundedBy');

                firstGeoObject.options.set('preset', 'islands#violetDotIconWithCaption');
                firstGeoObject.options.set('openBalloonOnClick', false);

                firstGeoObject.events.add('click', function() {
                    app.ports.ya_map__on_report.send(payload.id);
                });
                // Добавляем первый найденный геообъект на карту.
                yaMap.geoObjects.add(firstGeoObject);
            });
        });
    }

    app.ports.ya_map__destroy.subscribe(function() {
        if (yaMap !== null) {
            yaMap.destroy();
            yaMap = null;
        }
    });
});

