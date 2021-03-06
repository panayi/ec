`import Ember from 'ember'`
`import config from './config/environment'`

Router = Ember.Router.extend(location: config.locationType)

Router.map ->
  @route 'xEditor', path: '/x-editor'
  @route 'selectBox', path: '/select-box'

`export default Router`
