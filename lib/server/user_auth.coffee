exports.authenticate = (params, cb) ->
  get_user_id_for_email params.email, (user_id) ->
    if user_id
      validate_user_login user_id, params.pw, (success) ->
        if (success)
          cb({success: true, user_id: user_id})
        else
          cb({success: false, error_reason: "Password is wrong!"})
    else
      cb({success: false, error_reason: "User does not exist!"})
  

get_user_id_for_email = (email, cb) ->
  R.hget "email:" + email, "id", (err, user_id) ->
    cb user_id
  
validate_user_login = (user_id, password, cb) ->
  R.hget "dj:" + user_id, "pw", (err, pw) -> 
    if password == pw
      cb true
    else
      cb false