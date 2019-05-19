require('./src/executor.pcss');

var compiled = require('./src/Executor.elm');
var io = require('socket.io-client');

var socket = io('//carhook.ru');
socket.emit('join_room', 'executor');

function noop() { }

ymaps.ready(function () {
    var yaMap = null;
    var afterMapInited = noop;
    var app = compiled.Elm.Executor.init();

    socket.on('change_status', function(report) {
        app.ports.api__on_change_report.send(report);
    });

    socket.on('create_order', function(report) {
        app.ports.api__on_change_report.send(report);
    });

    app.ports.ya_map__init.subscribe(function (payload) {
        setTimeout(() => {
            ymaps.geolocation.get().then(function (result) {
                var mapContainer = document.getElementById(payload.nodeId);
                var bounds = result.geoObjects.get(0).properties.get('boundedBy');
                // Рассчитываем видимую область для текущей положения пользователя.
                var mapState = ymaps.util.bounds.getCenterAndZoom(
                    bounds,
                    [mapContainer.clientWidth, mapContainer.clientHeight]
                );
                createMap(payload, mapState);

                if (!payload.interactive) {
                    return;
                }

                result.geoObjects.options.set('preset', 'islands#redCircleIcon');
                yaMap.geoObjects.add(result.geoObjects);

            }, function () {
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
            controls: ['zoomControl', 'geolocationControl']
        }, config, {
            zoom: 13
        }));

        window.___ = yaMap;

        afterMapInited();
        afterMapInited = noop;
    }

    app.ports.ya_map__set_addresses.subscribe(function (addresses) {
        if (yaMap == null) {
            afterMapInited = function () {
                drawAddresses(addresses);
            }
        } else {
            drawAddresses(addresses);
        }
    });

    function drawAddresses(addresses) {
        yaMap.geoObjects.each(function(child) {
            if (child instanceof ymaps.Collection) {
                yaMap.geoObjects.remove(child);
            }
        });

        var collection = new ymaps.Collection();
        yaMap.geoObjects.add(collection);

        addresses.forEach(function (payload) {
            ymaps.geocode(payload.address, {
                results: 1
            }).then(function (result) {
                var firstGeoObject = result.geoObjects.get(0);
                // Координаты геообъекта.
                var coords = firstGeoObject.geometry.getCoordinates();
                // Область видимости геообъекта.
                var bounds = firstGeoObject.properties.get('boundedBy');

                firstGeoObject.options.set('preset', 'islands#violetDotIconWithCaption');
                firstGeoObject.options.set('openBalloonOnClick', false);

                firstGeoObject.events.add('click', function () {
                    app.ports.ya_map__on_report.send(payload.id);
                });
                // Добавляем первый найденный геообъект на карту.
                collection.add(firstGeoObject);
            });
        });
    }

    app.ports.ya_map__set_address.subscribe(function (address) {
        if (yaMap == null) {
            afterMapInited = function () {
                drawAddress(address);
            }
        } else {
            drawAddress(address);
        }
    });

    function drawAddress(address) {
        ymaps.geocode(address, {
            results: 1
        }).then(function (result) {
            var firstGeoObject = result.geoObjects.get(0);
            // Координаты геообъекта.
            var coords = firstGeoObject.geometry.getCoordinates();
            // Область видимости геообъекта.
            var bounds = firstGeoObject.properties.get('boundedBy');

            firstGeoObject.options.set('preset', 'islands#violetDotIconWithCaption');

            // Добавляем первый найденный геообъект на карту.
            yaMap.geoObjects.add(firstGeoObject);
            // Масштабируем карту на область видимости геообъекта.
            yaMap.setBounds(bounds, {
                // Проверяем наличие тайлов на данном масштабе.
                checkZoomRange: true
            });
        });
    }

    app.ports.ya_map__destroy.subscribe(function () {
        if (yaMap !== null) {
            yaMap.destroy();
            yaMap = null;
        }
    });
});

