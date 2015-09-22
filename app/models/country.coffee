`import Ember from 'ember'`

Country = Ember.Object.extend
  name: null
  code: null

buildPromise = ->
  request = new Ember.RSVP.Promise (resolve, reject) ->
    xhr = Ember.$.getJSON 'https://restcountries.eu/rest/v1/all'

    xhr.done (payload) ->
      payload = payload or []
      countries = payload.map (item) ->
        Country.create
          name: item.name
          code: item.alpha2Code
      resolve(countries)

    xhr.fail (error) ->
      Ember.Error('"https://restcountries.eu/rest/v1/all" request failed')
      reject(error)

  request

Country.reopenClass
  all: ->
    @_promise or @_promise = buildPromise()

`export default Country`
