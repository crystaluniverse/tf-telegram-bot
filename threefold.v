module main

import time
import os
import json
import cli

import dariotarantini.vgram
import despiegk.crystallib.gittools
import despiegk.crystallib.myconfig

const cfg = myconfig.get() or {panic(err)}

struct Session {
    pub mut:
        back_page_history []string
        forward_page_history []string
        current_page string
        current_input string
        userid string
        take_action bool
        message vgram.Message
        payment_token string
        bot vgram.Bot
        content_repo string
}

fn handle_page(mut session Session)?{
    session.bot.send_chat_action({chat_id: session.userid, action: "typing"})

    // all top level pages
    mut fspages := map[string]bool{}
    
    for item in os.ls(session.content_repo)?{
        p := os.join_path('templates', item)
        if os.is_file(p){
            fspages[item.trim_right('.md')] = true
        }else{
            fspages[item] = false
        }
    }

    // change current_page based on input if valid input
    // if starts with / search for up level pages
    if session.current_input != '' {
        userinput := session.current_input
        if userinput.starts_with('/'){
            mut userinputnoslash := userinput.trim_left('/')
            if userinputnoslash in fspages{
                if fspages[userinputnoslash]{
                    if userinputnoslash == 'home'{
                        userinputnoslash = ''
                    }
                    session.current_page = userinputnoslash
                    session.back_page_history << userinputnoslash
                }else{
                    session.current_page = userinputnoslash
                }

                session.back_page_history << userinputnoslash
            }
        }else{
            current_page := session.current_page + '.' + userinput
            p := os.join_path(session.content_repo, current_page.replace(".", "/"), "home.md")
            if os.exists(p){
                session.current_page = current_page
                session.back_page_history << current_page
            }        
        }
    }
    path := os.join_path(session.content_repo, session.current_page.replace(".", "/"), "home.md")
    content := os.read_file(path)?
    session.bot.send_message({chat_id: session.userid,text: content, parse_mode: "MarkdownV2"})
}

fn handle_back_cmd(mut session &Session)?{
    if session.back_page_history.len > 1 {
        current_page := session.back_page_history.pop()
        session.forward_page_history << current_page
        session.current_input = ''
        session.current_page = session.back_page_history[session.back_page_history.len - 1]
        session.take_action = true
        handle_page(mut session)?
    }else{
        session.bot.delete_message({chat_id: session.userid, message_id: session.message.message_id})
    }
}

fn handle_forward_cmd(mut session &Session)?{
    if session.forward_page_history.len > 0 {
        current_page := session.forward_page_history.pop()
        session.back_page_history << current_page
        session.current_input = ''
        session.current_page = current_page
        session.take_action = true
        handle_page(mut session)?
    }else{
        session.bot.delete_message({chat_id: session.userid, message_id: session.message.message_id})
    }
}

fn handle_shop_cmd(mut session &Session)?{
    session.bot.send_invoice({
        chat_id: session.userid,
        title: "Fantastic cloud Box",
        description: "foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo bar",
        provider_token: session.payment_token,
        need_name: true,
        need_phone_number: true,
        need_email: true,
        need_shipping_address: true,
        send_phone_number_to_provider: true,
        send_email_to_provider: true,
        is_flexible: true,
        photo_url: "https://core.telegram.org/file/811140095/1/lfTvDVqVS8M.43169/1a191248e6cf027581",
        photo_width: 200,
        photo_height: 200,
        payload: json.encode({'a': 1, 'b': 2}),
        currency: "USD",
        prices: json.encode([vgram.LabeledPrice{label: "total", amount: 10000}]),
    })
}

fn update_content(force_pull bool)?&gittools.GitRepo{

    mut pull := force_pull
    
    
    codepath := cfg.paths.code

    mut gt := gittools.new(codepath) or {
		return error_with_code('ERROR: cannot load gittools:$err', 2)
	}
	
    url := 'https://github.com/threefoldfoundation/tf_telegram'
    mut repo := gt.repo_get(name: 'tf_telegram') or {
        pull = false
        gt.repo_get_from_url(url: url pull: true, reset: false, branch: 'main') or {
			return error(' - ERROR: could not download site $url, do you have rights?\n$err\n$url')
	    }
	}

    if pull{
        repo.pull() or { return error('ERROR: cannot pull repo $repo.path :$err') }
    }

    return repo
}

fn run(cmd cli.Command)?{
    flags := cmd.flags.get_all_found()
	token := flags.get_string('token') or {
        println("Usage ./threefold --token <token> --paymenttoken <payment token>")
        return
    }

    payment_token := flags.get_string('paymenttoken') or {
        println("Usage ./threefold --token <token> --paymenttoken <payment token>")
        return
    }

    mut pull := true
    pull = flags.get_bool('update') or {
        false        
    }

    repo := update_content(pull)?

    bot := vgram.new_bot(token)

    mut updates := []vgram.Update{}
    mut last_offset := 0

    botstarttime := time.utc().unix

    mut sessions := map[string]&Session{}

    for {
        updates = bot.get_updates({offset: last_offset, limit: 100})
                
        for update in updates {
            if last_offset < update.update_id {
                last_offset = update.update_id
                
                // skip old messages prior to the time of running the bot
                if update.message.date < botstarttime{
                    continue
                }

                userid := update.message.from.id.str()

                if !(userid in sessions){
                    sessions[userid] = &Session{
                        userid: userid,
                        payment_token: payment_token,
                        bot: bot,
                        content_repo: repo.path
                    }
                    sessions[userid].back_page_history << ''
                }
                
                mut usersession := sessions[userid]
                mut userinput := update.message.text.trim_space()

                usersession.current_input = userinput
                usersession.message = update.message

                if userinput == '/forward'{
                    go handle_forward_cmd(mut usersession)
                }else if userinput == '/shop'{
                    go handle_shop_cmd(mut usersession)
                }else if userinput == '/back'{
                    go handle_back_cmd(mut usersession)
                }else{
                    go handle_page(mut usersession)
                }
            }
        }
    }
}

fn main(){
    tokenflag := cli.Flag{
		name: 'token'
		abbrev: 't'
		description: "Telegram bot API Token"
		flag: cli.FlagType.string
    }   

    paymenttokenflag := cli.Flag{
        name: 'paymenttoken'
        abbrev: 'p'
        description: 'Payment Token for the chose payment provider'
        flag: cli.FlagType.string
    }

    updateflag := cli.Flag{
        name: 'update'
        abbrev: 'u'
        description: 'Force pull tf_telegram repo (better to use  production)'
        flag: cli.FlagType.bool
    }

    run_exec := fn (cmd cli.Command) ? {
		run(cmd) ?
	}

    mut run_cmd := cli.Command{
		name: 'run'
		execute: run_exec
	}

    run_cmd.add_flag(tokenflag)
    run_cmd.add_flag(paymenttokenflag)
    run_cmd.add_flag(updateflag)

    mut main_cmd := cli.Command{
		name: 'runner'
		commands: [run_cmd]
		description: 'Threefold Telegram bot runner'
	}

	main_cmd.setup()
	main_cmd.parse(os.args)
}
