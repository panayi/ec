`import Ember from 'ember';`

ApplicationRoute = Ember.Route.extend
  actions:
    transitionTo: (name) ->
      @transitionTo(name)

`export default ApplicationRoute;`
