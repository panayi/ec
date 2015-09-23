`import Ember from 'ember'`
`import Post from '../models/post'`

XEditorRoute = Ember.Route.extend
  model: ->
    Post.create()

`export default XEditorRoute`
