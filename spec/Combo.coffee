noflo = require 'noflo'
chai = require 'chai'
http = require 'http'
uuid = require 'uuid'
express = require 'express'

getResultJSON = (res, callback) ->
  data = ''
  res.on 'data', (chunk) ->
    data += chunk
  res.on 'end', ->
    try
      json = JSON.parse data
      callback json
    catch e
      throw new Error e.message + ". Body:" + data

describe 'A Combo router with multiple filters', ->
  net = null

  before (done) ->
    noflo.loadFile 'test_graphs/ComboTest.fbp', {}, (network) ->
      net = network
      done()
  after (done) ->
    net.stop()
    done()

  it 'should block unauthorized requests', (done) ->
    options =
      hostname: 'localhost'
      port: 3031
      path: "/public/hello"
      method: 'GET'
    try
      req = http.request options, (res) ->
        chai.expect(res.headers['x-foo']).to.equal 'bar'
        chai.expect(res.statusCode).to.equal 403
        done()
      req.end()
    catch e
      done e

  it 'should handle GET', (done) ->
    options =
      hostname: 'localhost'
      port: 3031
      path: "/public/hello"
      method: 'GET'
      headers:
        'Pass': 'noflo'
    try
      req = http.request options, (res) ->
        if res.statusCode isnt 200
          return done new Error "Invalid status code: #{res.statusCode}"
        getResultJSON res, (json) ->
          chai.expect(json).to.be.a 'string'
          chai.expect(json).to.equal 'Hello'
          done()
      req.end()
    catch e
      done e

  it 'should handle POST', (done) ->
    newUserEmail = 'john' + uuid.v4().substr(0, 16) + '@example.com'
    reqData = JSON.stringify
      email: newUserEmail
    options =
      hostname: 'localhost'
      port: 3031
      path: "/public/world"
      method: 'POST'
      headers:
        'Content-Length': reqData.length
        'Pass': 'noflo'
    try
      req = http.request options, (res) ->
        if res.statusCode isnt 201
          return done new Error "Invalid status code: #{res.statusCode}"
        getResultJSON res, (json) ->
          chai.expect(json).to.be.an 'object'
          chai.expect(json.email).to.be.a 'string'
          chai.expect(json.email).to.equal newUserEmail
          done()
      req.write reqData
      req.end()
    catch e
      done e
