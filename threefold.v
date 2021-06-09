module main

import time
import os

import dariotarantini.vgram

const bot = vgram.new_bot("1836992937:AAEEYXyeQ0klNWJIze1JaAhDtQ1MqeqD9ZM")

struct Session {
    pub mut:
        back_page_history []string
        forward_page_history []string
        current_page string
        current_input string
        userid string
        take_action bool
        message vgram.Message
}

fn handle_page(mut session Session)?{
    bot.send_chat_action({chat_id: session.userid, action: "typing"})

    // all top level pages
    mut fspages := map[string]bool{}
    
    for item in os.ls('templates')?{
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
            p := os.join_path("templates", current_page.replace(".", "/"), "home.md")
            if os.exists(p){
                session.current_page = current_page
                session.back_page_history << current_page
            }        
        }
    }
    path := os.join_path("templates", session.current_page.replace(".", "/"), "home.md")
    println(session.current_page)
    println(path)
    content := os.read_file(path)?
    bot.send_message({chat_id: session.userid,text: content, parse_mode: "MarkdownV2"})
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
        bot.delete_message({chat_id: session.userid, message_id: session.message.message_id})
    }
}

fn handle_forward_cmd(mut session &Session)?{
    println("forward")
    println(session.forward_page_history)
    if session.forward_page_history.len > 0 {
        current_page := session.forward_page_history.pop()
        session.back_page_history << current_page
        session.current_input = ''
        session.current_page = current_page
        session.take_action = true
        handle_page(mut session)?
    }else{
        bot.delete_message({chat_id: session.userid, message_id: session.message.message_id})
    }
}

fn main(){
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
                    sessions[userid] = &Session{userid: userid}
                    sessions[userid].back_page_history << ''
                }
                
                mut usersession := sessions[userid]
                mut userinput := update.message.text.trim_space()

                usersession.current_input = userinput
                usersession.message = update.message

                if userinput == '/forward'{
                    handle_forward_cmd(mut usersession)?
                }else if userinput == '/back'{
                    handle_back_cmd(mut usersession)?
                }else{
                    handle_page(mut usersession) or {panic(err)}
                }
            }
        }
    }
}
