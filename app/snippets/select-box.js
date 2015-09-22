export default "{{select-box \n \
  content=availableOptions \n \
  optionLabelPath=\"content.label\" \n \
  optionValuePath=\"content.value\" \n \
  selection=selectedOptions \n \
  multiple=true \n \
  allowInsert=true \n \
  inserts=newOptions \n \
  sortProperties=\"firstName,lastName,email\" \n \
  prompt=\"Select\"}}";
