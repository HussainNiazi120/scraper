import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "url", "submitButton", "addMetaTag", "metaTagGroup", "metaTag", "fieldsList", "field", "fieldKey", "removeFieldButton", "fieldSelector"]

  connect() {
    this.submitButtonTarget.disabled = true
  }

  fieldTargetConnected(element) {
    this.validateForm()
  }

  fieldTargetDisconnected(element) {
    this.validateForm()
  }

  addRemoveMetaTag() {
    this._all_meta_tags_present() ? this._addNewMetaTag() : this._removeEmptyMetaTags()
  }

  _addNewMetaTag() {
    let newMetaTag = this.metaTagTarget.cloneNode(true)
    newMetaTag.value = ''
    this.metaTagGroupTarget.appendChild(newMetaTag)
  }

  addRemoveField() {
    this._fieldsValid() ? this._addNewField() : this._removeEmptyFields()
    this._resetRemoveFieldButtons()
  }

  _addNewField() {
    let newField = this.fieldTarget.cloneNode(true)
    newField.querySelector('input[name="fields[key]"]').value = ''
    newField.querySelector('input[name="fields[selector]"]').value = ''
    this.fieldsListTarget.appendChild(newField)
  }

  removeField(e) {
    e.target.closest('[data-form-target="field"]').remove()
    this._resetRemoveFieldButtons()
  }

  SerializePayload(e) {
    e.preventDefault()
    this._removeEmptyMetaTags()
    let fields = this._serializeFields()
    let meta = this._serializeMetaTags()
    fields["meta"] = meta
    let payload = this._createPayload(fields)
    this._sendPayload(payload)
  }

  _serializeFields() {
    let fields = {}
    this.fieldKeyTargets.forEach((fieldKey, index) => {
      if(fieldKey.value !== "" && this.fieldSelectorTargets[index].value !== "")
        fields[fieldKey.value] = this.fieldSelectorTargets[index].value
    })
    return fields
  }

  _serializeMetaTags() {
    return this.metaTagTargets.map(metaTag => metaTag.value)
  }

  _createPayload(fields) {
    return {
      authenticity_token: this.formTarget.querySelector('input[name="authenticity_token"]').value,
      url: this.urlTarget.value,
      fields: fields
    }
  }

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

  validateForm() {
    this.submitButtonTarget.disabled = !(this._urlValid() && this._fieldsValid())
  }

  _urlValid() {
    return this.urlTarget.value !== ""
  }

  _all_meta_tags_present() {
    return this.metaTagTargets.every(metaTag => metaTag.value !== "")
  }

  _removeEmptyMetaTags() {
    this.metaTagTargets.filter(metaTag => metaTag.value === "").forEach((metaTag, index, emptyMetaTags) => {
      if (emptyMetaTags.length > 1 && index === 0) {
        metaTag.remove()
      }
    })
  }

  _removeEmptyFields() {
    this.fieldTargets.filter(field => field.querySelector('input[name="fields[key]"]').value === "" && field.querySelector('input[name="fields[selector]"]').value === "").forEach((field, index, emptyFields) => {
      if (emptyFields.length > 1 && index === 0) {
        field.remove()
      }
    })
  }

  _resetRemoveFieldButtons() {
    this.removeFieldButtonTargets.forEach(removeFieldButton => removeFieldButton.disabled = false)
    if(this.fieldTargets.length === 1) {
      this.removeFieldButtonTargets[0].disabled = true
    }
    if(this.fieldTargets.length > 1) {
      this.removeFieldButtonTargets[this.fieldTargets.length - 1].disabled = true
    }
    this._removeEmptyFields()
  }

  _fieldsValid() {
    return this.fieldTargets.every((field, index) => {
      if (index !== this.fieldTargets.length - 1) {
        return field.querySelector('input[name="fields[key]"]').value !== "" && field.querySelector('input[name="fields[selector]"]').value !== ""
      }
      return true
    })
  }
}