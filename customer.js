const compiled = require('./src/Main.elm');

function noop() {}

ymaps.ready(function() {
    var yaMap = null;
    var afterMapInited = noop;
    var app = compiled.Elm.Main.init({
        flags: {}
    });

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

                if (!payload.interactive) {
                    return;
                }

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
            zoom: 17
        }))

        afterMapInited();
        afterMapInited = noop;

        if (!payload.interactive) {
            return;
        }

        var myPlacemark;

        yaMap.events.add('click', function(event) {
            var coords = event.get('coords');

            // Если метка уже создана – просто передвигаем ее.
            if (myPlacemark) {
                myPlacemark.geometry.setCoordinates(coords);
            }
            // Если нет – создаем.
            else {
                myPlacemark = createPlacemark(coords);
                yaMap.geoObjects.add(myPlacemark);
                // Слушаем событие окончания перетаскивания на метке.
                myPlacemark.events.add('dragend', function () {
                    getAddress(myPlacemark.geometry.getCoordinates());
                });
            }
            getAddress(coords);
        });
    }

    // Создание метки.
    function createPlacemark(coords) {
        return new ymaps.Placemark(coords, {
        }, {
            preset: 'islands#violetDotIconWithCaption',
            draggable: true
        });
    }

    // Определяем адрес по координатам (обратное геокодирование).
    function getAddress(coords) {
        ymaps.geocode(coords).then(function (res) {
            var firstGeoObject = res.geoObjects.get(0);

            app.ports.ya_map__on_address.send([
                firstGeoObject.getLocalities().length ? firstGeoObject.getLocalities() : firstGeoObject.getAdministrativeAreas(),
                firstGeoObject.getThoroughfare() || firstGeoObject.getPremise(),
                firstGeoObject.getPremiseNumber()
            ].join(", "));
        });
    }

    app.ports.ya_map__set_address.subscribe(function(address) {
        if (yaMap == null) {
            afterMapInited = function() {
                drawAddress(address);
            }
        } else {
            drawAddress(address);
        }
    });

    function drawAddress(address) {
        ymaps.geocode(address, {
            results: 1
        }).then(function(result) {
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

    app.ports.ya_map__destroy.subscribe(function() {
        if (yaMap !== null) {
            yaMap.destroy();
            yaMap = null;
        }
    });
});
