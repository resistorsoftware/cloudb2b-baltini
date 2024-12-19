import { Controller } from "@hotwired/stimulus"
import { flashNotice, flashError } from "../shopify_app/flash_messages"

import { post } from "@rails/request.js"

async function saveSettings (settings) {
  let response = await post("/edit", {
      contentType: "application/json",
      //responseKind: "turbo-stream",
      body: { settings: settings }
  })
  if (response.ok) {
    flashNotice("Settings were saved")
    Turbo.visit("/")
  } else {
    flashError("Failed to save settings")
  }
}

async function createEntry (settings) {
  let response = await post("/create", {
      contentType: "application/json",
      responseKind: "turbo-stream",
      body: { settings: settings }
  })
  if (response.ok) {
    flashNotice("Settings were saved")
    Turbo.visit("/")
  } else {
    flashError("Failed to save settings")
  }
}

export default class extends Controller {
  static targets = ["input"]

  connect () {
    console.log("In the realm of the home controller ")
  }

  removeRate (e) {
    e.preventDefault()
    console.log("Delete Country Code: ", e.params.countryCode)
   
    const okButton = Button.create(window.app, {label: 'Ok'});
    okButton.subscribe(Button.Action.CLICK, () => {
      //deleteEvent(this.element.dataset.eventId);
      myModal.dispatch(Modal.Action.CLOSE);
    });
    const cancelButton = Button.create(window.app, {label: 'Cancel'});
    cancelButton.subscribe(Button.Action.CLICK, () => {
      myModal.dispatch(Modal.Action.CLOSE);
    });
    const modalOptions = {
      title: 'Country Code Delete',
      message: 'Are you sure you want to delete this country and all the data associated with it?',
      footer: {
        buttons: {
          primary: okButton,
          secondary: [cancelButton],
        },
      },
    };
    const myModal = Modal.create(window.app, modalOptions);
    myModal.dispatch(Modal.Action.OPEN);
  }

  create (e) {
    e.preventDefault()
    let bad = []
    let settings = {}
    this.inputTargets.forEach(el => {
      let x = el.querySelector("input")
      if (x.type == 'number' && isNaN(x.valueAsNumber)) {
        //console.log("Bad number! ", x.valueAsNumber)
        bad.push(x.name)
      } else if(x.type == 'number') {
        settings[x.name] = x.valueAsNumber
      } else {
        settings[x.name] = x.value
      }
    })
    if (bad.length > 0) {
      flashError("Please enter a valid value for " + bad)
      return
    } else {
      createEntry(settings)
    }
  }

  save (e) {
    e.preventDefault()
    let bad = []
    let settings = {}
    this.inputTargets.forEach(el => {
      let x = el.querySelector("input")
      //console.log("Input element from el", x.valueAsNumber)
      if (isNaN(x.valueAsNumber)) {
        //console.log("Bad number! ", x.valueAsNumber)
        bad.push(x.name)
      } else {
        settings[x.name] = x.valueAsNumber
      }
    })
    //console.log("settings be ", settings, bad, bad.length)
    if (bad.length > 0) {
      flashError("Please enter a valid number for " + bad)
      return
    } else {
      settings["countryCode"] = this.element.dataset.code
      saveSettings(settings)
    }
  }
}

