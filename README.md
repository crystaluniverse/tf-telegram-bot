# TF-Telegram-Bot

## Prerequisites

Install vgram & crystallib

- Using vpm: `v install dariotarantini.vgram && v install despiegk.crystallib`  

## Quick Getting started
1. run bot server `v  run threefold.v run --token 1836992937:AAEEYXyeQ0klNWJIze1JaAhDtQ1MqeqD9ZM --paymenttoken 284685063:TEST:NzkwMDVhOTUzMjlj --update true`

2. using your telegram, visit `@HamdyTestBot` and interact with as shown
![](docs/1.png)
![](docs/2.png)
![](docs/payment8.png)
    use car number `4242 4242 4242 4242` for testing

## Getting started

### Create your own bot with payment support

1. Search for the `@botfather` telegram bot and start it  
2. Click on or type `/newbot` to create a new bot and follow his instructions  
3. On finish, `@botfather` will give you a token. Copy that token, it's your bot token will be used in communication with the bot
4. now while talking to `@botfather` type `/mybots` then select your bot

    ![](docs/payment1.png)
5. choose payments

    ![](docs/payment2.png)
6. Choose your payment provider

     ![](docs/payment3.png)
7. I used `Stripe` here but you can use another one
8. conenct to `Stripe testing` for testing or `stripe live` if you need a real account
    
    ![](docs/payment4.png)
9. Authorize

    ![](docs/payment5.png)

10. Now you gonna be redirected to website. Click on `Skip this form` if you are in testing mode

    ![](docs/payment6.png)
11. Now you are redirected back to the (payment provider) bot `stripe` in this case with a success message

    ![](docs/payment7.png)
12. Now you can see your payment token in `@botfather`

    ![](docs/payment9.png)

## Run
- compile `v threefold.v`
- Give execution permissions: `chmod u+x threefold`
- Run (use your tokens) `./threefold --token 1836992937:AAEEYXyeQ0klNWJIze1JaAhDtQ1MqeqD9ZM --paymenttoken 284685063:TEST:NzkwMDVhOTUzMjlj --update true`
- The tokens above belong to `@HamdyTestBot` in case you want to test with
- By default, the bot gets its content from https://github.com/threefoldfoundation/tf_telegram

- use flag `--update true` better use in production to foce pulling the content repo. Don't use during development if you are changing content in the `tf_repo` locally to avoid merge conflicts

    ```
    v  run threefold.v run --help
    Usage: runner run [flags]

    Flags:
    -t  --token         Telegram bot API Token
    -p  --paymenttoken  Payment Token for the chose payment provider
    -u  --update        Force pull tf_telegram repo (better to use  production)
    -h  --help          Prints help information.

    ```
## How to set up pages

- use the dir `templates` to put markdown for communicating with users
- `templates` dir and any sub directory must contain `home.md` page
- `templates/home.md` represents the greeting message or your home page this is sent to user when user first says `hi` or `/home`

- All sub directories under `templates` are top level commands `/{dir_name}` for instance if we have `templates/farming` & `templates/cloud` these willh be accessible through `/farming` & `/cloud` respectively provided that each sub directory contains `home.md`

- under each toplevel directrory sub dirs there are named with the choices u ask user to choose 

    ```
    tf_telegram (repo)
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
