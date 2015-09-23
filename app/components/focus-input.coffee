`import Ember from 'ember'`

FocusInputComponent = Ember.TextField.extend
  becomeFocused: ( ->
    Ember.run.scheduleOnce 'afterRender', =>
      Ember.run.later =>
        this.$().focus()
      , 1
  ).on('didInsertElement')

  _onKeyDown: ((event) ->
    @sendAction('onKeyDown', event)
  ).on('keyDown')

`export default FocusInputComponent`
