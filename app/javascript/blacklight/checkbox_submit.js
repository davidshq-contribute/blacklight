/* Converts a "toggle" form, with single submit button to add/remove
   something, like used for Bookmarks, into an AJAXy checkbox instead.
   Apply to a form. Does require certain assumption about the form:
    1) The same form 'action' href must be used for both ADD and REMOVE
       actions, with the different being the hidden input name="_method"
       being set to "put" or "delete" -- that's the Rails method to pretend
       to be doing a certain HTTP verb. So same URL, PUT to add, DELETE
       to remove. This plugin assumes that.
       Plus, the form this is applied to should provide a data-doc-id
       attribute (HTML5-style doc-*) that contains the id/primary key
       of the object in question -- used by plugin for a unique value for
       DOM id's.
  Uses HTML for a checkbox compatible with Bootstrap 4.
   new CheckboxSubmit(document.querySelector('form.something')).render()
*/
export default class CheckboxSubmit {
  constructor(form) {
    this.form = form
  }

  async clicked(evt) {
    this.spanTarget.innerHTML = this.form.getAttribute('data-inprogress')
    this.labelTarget.setAttribute('disabled', 'disabled');
    this.checkboxTarget.setAttribute('disabled', 'disabled');
    const response = await fetch(this.formTarget.getAttribute('action'), {
      body: new FormData(this.formTarget),
      method: this.formTarget.getAttribute('method').toUpperCase(),
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content
      }
    })
    this.labelTarget.removeAttribute('disabled')
    this.checkboxTarget.removeAttribute('disabled')
    if (response.ok) {
      const json = await response.json()
      this.updateStateFor(!this.checked)
      document.querySelector('[data-role=bookmark-counter]').innerHTML = json.bookmarks.count
    } else {
      alert('Error')
    }
  }

  get checked() {
    return (this.form.querySelectorAll('input[name=_method][value=delete]').length != 0)
  }

  get formTarget() {
    return this.form
  }

  get labelTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="label"]')
  }

  get checkboxTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="checkbox"]')
  }

  get spanTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="span"]')
  }

  updateStateFor(state) {
    this.checkboxTarget.checked = state

    if (state) {
      this.labelTarget.classList.add('checked')
      //Set the Rails hidden field that fakes an HTTP verb
      //properly for current state action.
      this.formTarget.querySelector('input[name=_method]').value = 'delete'
      this.spanTarget.innerHTML = this.form.getAttribute('data-present')
    } else {
      this.labelTarget.classList.remove('checked')
      this.formTarget.querySelector('input[name=_method]').value = 'put'
      this.spanTarget.innerHTML = this.form.getAttribute('data-absent')
    }
  }
}
