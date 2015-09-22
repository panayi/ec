`import Ember from 'ember'`
`import Country from '../models/country'`
`import User from '../models/user'`
`import Email from '../models/email'`

SelectBoxRoute = Ember.Route.extend
  model: ->
    Ember.RSVP.hash
      countries: Country.all()
      users: User.all()
      emails: Email.all()

  setupController: (controller, collections) ->
    @_super(controller, collections)
    controller.setProperties
      countries: collections.countries
      users: collections.users
      emails: collections.emails

`export default SelectBoxRoute`
