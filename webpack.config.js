const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');

const getRules = env => [
    {
        test: /\.(eot|ttf|woff|woff2|svg)$/,
        use: {
            loader: 'file-loader',
            options: {
                publicPath: '/',
                name: 'static/css/[hash].[ext]'
            }
        }
    }
].concat(env.PRODUCTION
    ? [
        {
            test: /\.elm$/,
            exclude: [
                /elm-stuff/,
                /node_modules/
            ],
            use: {
                loader: 'elm-webpack-loader',
                options: {
                    optimize: true
                }
            }
        },
        {
            test: /\.p?css$/,
            use: ExtractTextPlugin.extract({
                fallback: 'style-loader',
                use: [
                    {
                        loader: 'css-loader',
                        options: {
                            importLoaders: 1,
                            minimize: true
                        }
                    },
                    {
                        loader: 'postcss-loader'
                    }
                ]
            })
        }
    ]
    : [
        {
            test: /\.elm$/,
            exclude: [
                /elm-stuff/,
                /node_modules/
            ],
            use: {
                loader: 'elm-webpack-loader',
                options: {
                    debug: true
                }
            }
        },
        {
            test: /\.p?css$/,
            use: [
                {
                    loader: 'style-loader'
                },
                {
                    loader: 'css-loader',
                    options: {
                        importLoaders: 1
                    }
                },
                {
                    loader: 'postcss-loader'
                }
            ]
        }
    ]
);

const getPlugins = env => [
    new webpack.DefinePlugin({
        PRODUCTION: JSON.stringify(env.PRODUCTION),
        DEVELOPMENT: JSON.stringify(env.DEVELOPMENT)
    }),
    new HtmlWebpackPlugin({
        template: path.resolve('./index.html'),
        inject: 'body',
        // favicon: path.resolve('./src/favicon.ico'),
        minify: env.PRODUCTION && {
            caseSensitive: true,
            collapseBooleanAttributes: true,
            collapseInlineTagWhitespace: true,
            collapseWhitespace: true,
            quoteCharacter: '"',
            removeAttributeQuotes: true,
            removeComments: true,
            removeEmptyAttributes: true,
            useShortDoctype: true
        },
        GOOGLE_ANALYTICS_ID: env.GOOGLE_ANALYTICS_ID
    })
].concat(env.PRODUCTION
    ? [
        new ExtractTextPlugin({
            filename: '[name].css',
            ignoreOrder: true
        }),
        new OptimizeCSSAssetsPlugin()
    ]
    : []
);

module.exports = env => ({
    entry: [
        '@fortawesome/fontawesome-free/css/all.css',
        'bootstrap/dist/css/bootstrap.css',
        path.resolve('./src/styles.css'),
        path.resolve('./customer.js')
    ],

    output: {
        path: path.resolve('./build'),
        filename: '[name].js',
        publicPath: '/'
    },

    resolve: {
        extensions: [ '.js' ]
    },

    module: {
        noParse: /\.elm$/,
        rules: getRules(env)
    },

    devServer: {
        historyApiFallback: true
    },

    plugins: getPlugins(env),

    devtool: env.PRODUCTION ? false : 'eval-source-map',

    mode: env.PRODUCTION ? 'production' : 'development',

    optimization: {
        minimize: env.PRODUCTION
    }
});
