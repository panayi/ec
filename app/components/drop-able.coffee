`import Ember from 'ember'`

DropAbleComponent = Ember.Component.extend
  classNames: ['dropable']
  classNameBindings: ['isDragOver']

  isDragOver: false

  dragOver: (event) ->
    Ember.run.debounce(this, =>
      @set('isDragOver', true)
    , 100, true)
    event.preventDefault()

  dragLeave: (event) ->
    @set('isDragOver', false)
    event.preventDefault()

  drop: (event) ->
    @set('isDragOver', false)
    event.preventDefault()
    @sendAction('action', event, @get('param1'), @get('param2'), @get('param3'))

`export default DropAbleComponent`
