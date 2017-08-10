module.exports = {
  entry: __dirname + "/web/static/js/app.js",
  output: {
    path: __dirname + "/priv/static/js",
    filename: "app.js"
  },
  module: {
        rules: [
            { 
                test: /\.js$/, 
                loader: 'buble?objectAssign=Object.assign!eslint',
                exclude: /node_modules/
            },
            {
                enforce: 'pre',
                test: /\.vue$/,
                loader: 'eslint',
                exclude: /node_modules/
            },
            {
                test: /\.vue$/,
                loader: 'vue',
                options: {
                    loaders: {
                        js: 'buble?objectAssign=Object.assign'
                    }
                },
                exclude: /node_modules/
            }]
  },
};
