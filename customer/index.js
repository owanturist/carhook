const compiled = require('./Main.elm');

ymaps.ready(function() {
    var yaMap = null;
    var app = compiled.Elm.Main.init({
        flags: {}
    });

    app.ports.ya_map__init.subscribe(function() {
        setTimeout(() => {
            if (yaMap !== null) {
                yaMap.destroy();
            }

            yaMap = new ymaps.Map('ya-map', {
                center: [55.0252534, 82.911067],
                zoom: 10
            });
        }, 50);
    });

    app.ports.ya_map__destroy.subscribe(function() {
        if (yaMap !== null) {
            yaMap.destroy();
            yaMap = null;
        }
    });
});
