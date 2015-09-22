`import Ember from 'ember'`
`import selectBoxSnippet from '../snippets/select-box'`

SelectBoxController = Ember.Controller.extend
  selectBoxSnippet: selectBoxSnippet

  actions:
    remove: (item, selectedItems) ->
      selectedItems.removeObject(item)

    deselect: (key) ->
      @set(key, null)

`export default SelectBoxController`
