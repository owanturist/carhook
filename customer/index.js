const compiled = require('./Main.elm');

ymaps.ready(function() {
    var yaMap = null;
    var app = compiled.Elm.Main.init({
        flags: {}
    });

    app.ports.ya_map__init.subscribe(function(nodeId) {
        setTimeout(() => {
            ymaps.geolocation.get().then(function(result) {
                var mapContainer = document.getElementById(nodeId);
                var bounds = result.geoObjects.get(0).properties.get('boundedBy');
                    // Рассчитываем видимую область для текущей положения пользователя.
                var mapState = ymaps.util.bounds.getCenterAndZoom(
                    bounds,
                    [mapContainer.clientWidth, mapContainer.clientHeight]
                );
                createMap(nodeId, mapState);

                result.geoObjects.options.set('preset', 'islands#redCircleIcon');
                yaMap.geoObjects.add(result.geoObjects);

            }, function() {
                // Если местоположение невозможно получить, то просто создаем карту.
                createMap(nodeId, {
                    center: [55.0252534, 82.911067]
                });
            });
        }, 50);
    });

    function createMap(nodeId, config) {
        if (yaMap !== null) {
            yaMap.destroy();
        }

        yaMap = new ymaps.Map(nodeId, Object.assign({
            controls: [ 'zoomControl', 'geolocationControl' ]
        }, config, {
            zoom: 17
        }))
    }

    app.ports.ya_map__destroy.subscribe(function() {
        if (yaMap !== null) {
            yaMap.destroy();
            yaMap = null;
        }
    });
});
