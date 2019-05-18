const import_ = require('postcss-import');
const url = require('postcss-url');
const mediaVariables = require('postcss-media-variables');
const customProperties = require('postcss-custom-properties');
const customMedia = require('postcss-custom-media');
const calc = require('postcss-calc');
const nested = require('postcss-nested');
const colorHexAlpha = require('postcss-color-hex-alpha');
const colorFunction = require('postcss-color-function');
const autoprefixer = require('autoprefixer');

module.exports = {
    plugins: [
        import_(),
        url(),
        mediaVariables(),
        customMedia(),
        customProperties,
        calc({
            precision: 2
        }),
        mediaVariables(),
        nested(),
        colorHexAlpha(),
        colorFunction(),
        autoprefixer()
    ]
};
