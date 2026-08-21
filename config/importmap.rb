# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "tiptap", to: "tiptap.js"
pin "codemirror-editor", to: "codemirror.js"
pin "lib/code_mirror", to: "lib/code_mirror.js"
pin_all_from "app/javascript/controllers", under: "controllers"
