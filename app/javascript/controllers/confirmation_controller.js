import { Controller } from "@hotwired/stimulus"
import { destroy } from '@rails/request.js'
import { flashNotice, flashError } from "../shopify_app/flash_messages"

async function deleteRate (code) {
  console.log("Doing a delete on country code ", code)
  const response = await destroy(`/home?code=${code}`, {contentType: "application/json", responseKind: "turbo-stream"});
  if (response.ok) {    
    flashNotice("Completed Delete Successfully");
  } else {
    console.log("Returned from delete badly");
    flashError("Error happened");
  }
}

export default class extends Controller {
  connect () {
    this.countryCode = ""
  }

  show(event) {
    console.log("Show Confirmation is giving", event.params.code)
    this.countryCode = event.params.code
    if (this.confirmed) return

    event.preventDefault()

    const modalElement = document.querySelector(event.params.target)
    const modal = this.application.getControllerForElementAndIdentifier(modalElement, "modal")
    modal.open()

    window.activeConfirmation = this
  }

  confirm() {
    this.confirmed = true
    deleteRate(this.countryCode)
    this.element.click()
  }
}
