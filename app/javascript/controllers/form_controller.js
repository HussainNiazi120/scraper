import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "url", "submitButton", "addMetaTag", "metaTagGroup", "metaTag", "fieldsList", "field", "fieldKey", "removeFieldButton", "fieldSelector"]

  connect() {
    this.disableSubmitButton()
  }

  fieldTargetConnected(element) {
    this.validateForm()
  }

  fieldTargetDisconnected(element) {
    this.validateForm()
  }

  // Add or remove meta tags based on their presence
  addRemoveMetaTag() {
    this._all_meta_tags_present() ? this._addNewMetaTag() : this._removeEmptyMetaTags()
  }

  // Add a new meta tag
  _addNewMetaTag() {
    let newMetaTag = this.metaTagTarget.cloneNode(true)
    newMetaTag.value = ''
    this.metaTagGroupTarget.appendChild(newMetaTag)
  }

  // Add or remove fields based on their validity
  addRemoveField() {
    this._fieldsValid() ? this._addNewField() : this._removeEmptyFields()
    this._resetRemoveFieldButtons()
  }

  // Add a new field
  _addNewField() {
    let newField = this.fieldTarget.cloneNode(true)
    newField.querySelector('input[name="fields[key]"]').value = ''
    newField.querySelector('input[name="fields[selector]"]').value = ''
    this.fieldsListTarget.appendChild(newField)
  }

  // Remove a field
  removeField(e) {
    e.target.closest('[data-form-target="field"]').remove()
    this._resetRemoveFieldButtons()
  }

  // Serialize the payload and send it
  SerializePayload(e) {
    e.preventDefault()
    this._removeEmptyMetaTags()
    let fields = this._serializeFields()
    let meta = this._serializeMetaTags()
    fields["meta"] = meta
    let payload = this._createPayload(fields)
    this._sendPayload(payload)
  }

  // Serialize the fields
  _serializeFields() {
    let fields = {}
    this.fieldKeyTargets.forEach((fieldKey, index) => {
      if(fieldKey.value !== "" && this.fieldSelectorTargets[index].value !== "")
        fields[fieldKey.value] = this.fieldSelectorTargets[index].value
    })
    return fields
  }

  // Serialize the meta tags
  _serializeMetaTags() {
    return this.metaTagTargets.map(metaTag => metaTag.value)
  }

  // Create the payload
  _createPayload(fields) {
    return {
      authenticity_token: this.formTarget.querySelector('input[name="authenticity_token"]').value,
      url: this.urlTarget.value,
      fields: fields
    }
  }

  // Send the payload
  _sendPayload(payload) {
    fetch('scraper/scrape', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: JSON.stringify(payload)
    }).then(response => {
      if (response.ok) {
        return response.text()
      } else {
        throw new Error('Network response was not ok.')
      }
    }).then(data => {
      Turbo.renderStreamMessage(data)
    }).catch(error => {
      console.error('There has been a problem with your fetch operation: ', error)
    })
  }

  // Validate the form
  validateForm() {
    this.submitButtonTarget.disabled = !(this._urlValid() && this._fieldsValid())
    this.submitButtonTarget.disabled ? this.disableSubmitButton() : this.enableSubmitButton()
  }

  // Check if the URL is valid
  _urlValid() {
    return this.urlTarget.value !== ""
  }

  // Check if all meta tags are present
  _all_meta_tags_present() {
    return this.metaTagTargets.every(metaTag => metaTag.value !== "")
  }

  // Remove empty meta tags
  _removeEmptyMetaTags() {
    this.metaTagTargets.filter(metaTag => metaTag.value === "").forEach((metaTag, index, emptyMetaTags) => {
      if (emptyMetaTags.length > 1 && index === 0) {
        metaTag.remove()
      }
    })
  }

  // Remove empty fields
  _removeEmptyFields() {
    this.fieldTargets.filter(field => field.querySelector('input[name="fields[key]"]').value === "" && field.querySelector('input[name="fields[selector]"]').value === "").forEach((field, index, emptyFields) => {
      if (emptyFields.length > 1 && index === 0) {
        field.remove()
      }
    })
  }

  // Reset the remove field buttons
  _resetRemoveFieldButtons() {
    this.removeFieldButtonTargets.forEach(removeFieldButton => removeFieldButton.disabled = false)
    this.removeFieldButtonTargets.forEach(removeFieldButton => removeFieldButton.classList.remove('cursor-not-allowed', 'opacity-50'))
    
    if(this.fieldTargets.length === 1) {
      this.disableRemoveFieldButton(this.removeFieldButtonTargets[0])
    }
    if(this.fieldTargets.length > 1) {
      this.disableRemoveFieldButton(this.removeFieldButtonTargets[this.fieldTargets.length - 1])
    }
    this._removeEmptyFields()
  }

  // Check if the fields are valid
  _fieldsValid() {
    return this.fieldTargets.every((field, index) => {
      if (index !== this.fieldTargets.length - 1) {
        return field.querySelector('input[name="fields[key]"]').value !== "" && field.querySelector('input[name="fields[selector]"]').value !== ""
      }
      return true
    })
  }

  // Disable the submit button
  disableSubmitButton() {
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.classList.add('cursor-not-allowed', 'opacity-50')
  }

  // Enable the submit button
  enableSubmitButton() {
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.classList.remove('cursor-not-allowed', 'opacity-50')
  }

  // Disable the remove field button
  disableRemoveFieldButton(button) {
    button.disabled = true
    button.classList.add('cursor-not-allowed', 'opacity-50')
  }
}