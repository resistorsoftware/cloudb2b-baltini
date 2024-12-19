import { Controller } from "@hotwired/stimulus"
import { post } from '@rails/request.js'
import { flashNotice, flashError } from "../shopify_app/flash_messages"

export default class extends Controller {
  static values = {url: String}

  async makeRequest(event) {
    event.preventDefault()

    const response = await post(this.urlValue)
    if (response.ok) {
      const body = await response.json
      flashNotice(body.message)
    } else {
      flashError('Failed to make request to the backend')
    }
  }
}
