#!/bin/bash

# ONLY USED FOR DEVELOPMENT. You won't need it in runtime

MSYS_NO_PATHCONV=1 elm-live src/Main.elm \
    --port 8011 \
    --proxy-prefix "/api" \
    --proxy-host "http://127.0.0.1:8000" \
    --start-page index.html \
    --pushstate true \
    -- \
    --output=index.js
