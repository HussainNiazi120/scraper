import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="fields"
export default class extends Controller {
  static targets = ["form",
                    "url",
                    "submitButton",
                    "addMetaTag",
                    "metaTagGroup",
                    "metaTag",
                    "fieldsList",
                    "field",
                    "fieldKey",
                    "removeFieldButton",
                    "fieldSelector"]

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
    if(this._all_meta_tags_present()) {
      let newMetaTag = this.metaTagTarget.cloneNode(true)
      newMetaTag.value = '';
      this.metaTagGroupTarget.appendChild(newMetaTag)
    }else {
      this._removeEmptyMetaTags()
    }
  }

  addRemoveField() {
    if(this._fieldsValid()) {
      let newField = this.fieldTarget.cloneNode(true)
      // set the value of child key and selector to empty
      newField.querySelector('input[name="fields[key]"]').value = '';
      newField.querySelector('input[name="fields[selector]"]').value = '';
      this.fieldsListTarget.appendChild(newField)
    }else {
      this._removeEmptyFields()
    }
    this._resetRemoveFieldButtons()
  }

  removeField(e) {
    // remove parent element with data-form-target="field"
    e.target.closest('[data-form-target="field"]').remove()
    this._resetRemoveFieldButtons()
  }

  SerializePayload(e) {
    e.preventDefault()
  
    // Remove empty meta tags
    this.metaTagTargets.filter((metaTag) => {
      if(metaTag.value === "")
        metaTag.remove()
    })

    // serialize fields
    let fields = {};
    this.fieldKeyTargets.forEach((fieldKey, index) => {
      if(fieldKey.value !== "" && this.fieldSelectorTargets[index].value !== "")
        fields[fieldKey.value] = this.fieldSelectorTargets[index].value;
    });

    let meta = this.metaTagTargets.map((metaTag) => {
      return metaTag.value;
    });

    fields["meta"] = meta;

    let payload = {
      authenticity_token: this.formTarget.querySelector('input[name="authenticity_token"]').value,
      url: this.urlTarget.value,
      fields: fields
    }
    
    fetch('scrapper/scrap', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: JSON.stringify(payload)
    }).then(response => {
      if (response.ok) {
        return response.text();
      } else {
        throw new Error('Network response was not ok.');
      }
    }).then(data => {
      Turbo.renderStreamMessage(data);
    }).catch(error => {
      console.error('There has been a problem with your fetch operation: ', error);
    });
  }

  validateForm() {
    if (this._urlValid() && this._fieldsValid()) {
      this.submitButtonTarget.disabled = false
    }else {
      this.submitButtonTarget.disabled = true
    }
  }

  _urlValid() {
    if (this.urlTarget.value === "") {
      return false
    } else {
      return true
    }
  }

  _all_meta_tags_present() {
    let all_present = true
    this.metaTagTargets.forEach((metaTag) => {
      if (metaTag.value === "") {
        all_present = false
      }
    })
    return all_present
  }

  _removeEmptyMetaTags() {
    let emptyMetaTags = this.metaTagTargets.filter((metaTag) => {
      return metaTag.value === ""
    })
    if (emptyMetaTags.length > 1) {
      emptyMetaTags[0].remove();
    }
  }

  _removeEmptyFields() {
    let emptyFields = this.fieldTargets.filter((field) => {
      return field.querySelector('input[name="fields[key]"]').value === "" && field.querySelector('input[name="fields[selector]"]').value === "";
    })
    if (emptyFields.length > 1) {
      emptyFields[0].remove();
    }
  }

  _resetRemoveFieldButtons() {
    // enable removeFieldButtons
      this.removeFieldButtonTargets.forEach((removeFieldButton) => {
        removeFieldButton.disabled = false
    })

    // disable first removeFieldButton if only one field is present
    if(this.fieldTargets.length === 1) {
      this.removeFieldButtonTargets[0].disabled = true
    }

    // disable last removeFieldButton if there are more than 1 fields
    if(this.fieldTargets.length > 1) {
      this.removeFieldButtonTargets[this.fieldTargets.length - 1].disabled = true
    }

    this._removeEmptyFields()
  }

  _fieldsValid() {
    let fieldsValid = true
    this.fieldTargets.forEach((field) => {
      if (field !== this.fieldTargets[this.fieldTargets.length - 1]) {
        if (field.querySelector('input[name="fields[key]"]').value === "" || field.querySelector('input[name="fields[selector]"]').value === "") {
          // ignore if the field is the last field
          fieldsValid = false
        }
      }
    })
    return fieldsValid
  }
}