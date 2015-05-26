var pkg = module.exports = function(options){

    var Parser = require('./lib/parser');

    return {
        Parser: Parser,
        createParser: function(filename){
            return new Parser(filename, options)
        }
    }
}