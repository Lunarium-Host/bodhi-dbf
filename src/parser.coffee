{EventEmitter} = require 'events'
Header = require './header'
fs = require 'fs'

absDate = (year, month, date) ->
    pad = (num) ->
      norm = Math.abs(Math.floor(num));
      if norm < 10
        norm = '0' + norm
      else
        norm = '' + norm

    return new Date(year + '-' + pad(month) + '-' + pad(date) + 'T00:00:00Z')

class Parser extends EventEmitter

    constructor: (@filename, @options) ->
      @options = @options || {}

    parse: =>
        @emit 'start', @

        @header = new Header @filename
        @header.parse (err) =>

            @emit 'header', @header

            sequenceNumber = 0

            fs.readFile @filename, 'binary', (err, buffer) =>
                throw err if err

                loc = @header.start
                while loc < (@header.start + @header.numberOfRecords * @header.recordLength) and loc < buffer.length
                    @emit 'record', @parseRecord ++sequenceNumber, buffer.slice loc, loc += @header.recordLength

                @emit 'end', @

        return @

    parseRecord: (sequenceNumber, buffer) =>
        record = {
            '@sequenceNumber': sequenceNumber
            '@deleted': (buffer.slice 0, 1)[0] isnt 32
        }

        loc = 1
        for field in @header.fields
            do (field) =>
                record[field.name] = @parseField field, buffer.slice loc, loc += field.length

        return record

    parseField: (field, buffer) =>

      emptyVal = @options.emptyVal || null

      value = (buffer.toString 'binary').replace /^\x20+|\x20+$/g, ''

      switch field.type
          when 'C'
            value = value || emptyVal
          when 'N', 'F'
            value = parseFloat (value)
            if isNaN(value)
              value = emptyVal
          when 'L'
            if value=='Y' or value=='y' or value=='T' or value=='t'
              value = true
            else if value=='N' or value=='n' or value=='F' or value=='f'
              value = false
            else value = emptyVal
          when 'D'
            yy = parseInt buffer.slice(0, 4)
            mm = parseInt buffer.slice(4, 6)
            dd = parseInt buffer.slice(6, 8)
            if isNaN(yy)
              value = emptyVal
            else
              value = absDate(yy, mm, dd)
          else
            value = value || emptyVal

      return value

module.exports = Parser
