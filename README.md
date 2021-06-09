# TF-Telegram-Bot

## Prerequisites

Install vgram

- Using vpm: `v install dariotarantini.vgram`  
- Using vpkg: `vpkg get vgram`

## Getting started  
1. Search for the “@botfather” telegram bot and start it  
2. Click on or type /newbot to create a new bot and follow his instructions  
3. Copy the token and change `const bot = vgram.new_bot("{token}")`
` in [threefold.v](./threefold.v)


## Run

- `v run threefold.v`

## How to set up pages

- use the dir `templates` to put markdown for communicating with users
- `templates` dir and any sub directory must contain `home.md` page
- `templates/home.md` represents the greeting message or your home page this is sent to user when user first says `hi` or `/home`

- All sub directories under `templates` are top level commands `/{dir_name}` for instance if we have `templates/farming` & `templates/cloud` these willh be accessible through `/farming` & `/cloud` respectively provided that each sub directory contains `home.md`

- under each toplevel directrory sub dirs there are named with the choices u ask user to choose 

    ```
    templates
        |_home.md  (home page) or /hi
        |_ farming
            |_ farming.md  /farming
            |_ 1
                |_ home.md  if user chose (1) while in farming
            |
            |_ 2
                |_ home.md  if user chose (2) while in farming
    ```

- we have `/back` and `/forward` to navigate between pages same as in browser

## Example:

![](docs/1.png)
![](docs/2.png)
